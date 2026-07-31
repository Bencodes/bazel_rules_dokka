package rules.dokka;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import org.jetbrains.dokka.ConfigurationJsonUtilsKt;
import org.jetbrains.dokka.ConfigurationKt;
import org.jetbrains.dokka.DokkaConfiguration;
import org.jetbrains.dokka.DokkaConfigurationImpl;
import org.jetbrains.dokka.DokkaGenerator;
import org.jetbrains.dokka.DokkaModuleDescriptionImpl;
import org.jetbrains.dokka.LinkMapperKt;
import org.jetbrains.dokka.PluginConfigurationImpl;
import org.jetbrains.dokka.utilities.DokkaConsoleLogger;

/**
 * Runs Dokka in-process with paths resolved inside the Bazel action's execution root.
 *
 * <p>Normal configurations use Dokka's documented JSON parser. Multi-module manifests are
 * converted to typed module descriptions because Dokka does not document the aggregate {@code
 * modules} JSON representation.
 */
public final class DokkaGeneratorRunner {
  private static final String MULTI_MODULE_MODE = "rules_dokka_multi_module";
  private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

  public static void main(String[] args) throws Exception {
    if (args.length != 1) {
      throw new IllegalArgumentException("usage: DokkaGeneratorRunner CONFIGURATION");
    }

    ObjectNode root = (ObjectNode) OBJECT_MAPPER.readTree(Paths.get(args[0]).toFile());
    DokkaConfiguration configuration =
        MULTI_MODULE_MODE.equals(root.path("runnerMode").asText())
            ? multiModuleConfiguration(root)
            : standardConfiguration(root);
    new DokkaGenerator(configuration, new DokkaConsoleLogger()).generate();
  }

  private static DokkaConfiguration standardConfiguration(ObjectNode root) throws Exception {
    absolutizeField(root, "outputDir");
    absolutizeOptionalField(root, "cacheRoot");
    absolutizeArray(root, "includes");
    absolutizeArray(root, "pluginsClasspath");

    JsonNode sourceSets = root.path("sourceSets");
    if (sourceSets.isArray()) {
      for (JsonNode sourceSetNode : (ArrayNode) sourceSets) {
        ObjectNode sourceSet = (ObjectNode) sourceSetNode;
        for (String field :
            List.of(
                "classpath",
                "includes",
                "samples",
                "sourceRoots",
                "suppressedFiles")) {
          absolutizeArray(sourceSet, field);
        }
        JsonNode sourceLinks = sourceSet.path("sourceLinks");
        if (sourceLinks.isArray()) {
          for (JsonNode sourceLinkNode : (ArrayNode) sourceLinks) {
            absolutizeOptionalField((ObjectNode) sourceLinkNode, "localDirectory");
          }
        }
      }
    }

    String json = OBJECT_MAPPER.writeValueAsString(root);
    DokkaConfiguration configuration =
        ConfigurationKt.apply(
            ConfigurationJsonUtilsKt.DokkaConfigurationImpl(json),
            ConfigurationJsonUtilsKt.GlobalDokkaConfiguration(json));
    for (DokkaConfiguration.DokkaSourceSet sourceSet : configuration.getSourceSets()) {
      sourceSet.getExternalDocumentationLinks().addAll(LinkMapperKt.defaultLinks(sourceSet));
    }
    return configuration;
  }

  private static DokkaConfiguration multiModuleConfiguration(ObjectNode root) {
    Path outputDirectory = absolutePath(requiredText(root, "outputDir"));
    List<DokkaModuleDescriptionImpl> modules = new ArrayList<>();
    JsonNode moduleNodes = root.path("modules");
    if (!moduleNodes.isArray() || moduleNodes.isEmpty()) {
      throw new IllegalArgumentException("Multi-module Dokka manifest must contain modules");
    }

    for (JsonNode moduleNode : (ArrayNode) moduleNodes) {
      ObjectNode module = (ObjectNode) moduleNode;
      Path relativeOutput = Paths.get(requiredText(module, "relativePathToOutputDirectory"));
      if (relativeOutput.isAbsolute()
          || !outputDirectory.resolve(relativeOutput).normalize().startsWith(outputDirectory)) {
        throw new IllegalArgumentException(
            "Module output escapes the aggregate documentation directory: " + relativeOutput);
      }
      modules.add(
          new DokkaModuleDescriptionImpl(
              requiredText(module, "name"),
              relativeOutput.toFile(),
              files(module.path("includes")),
              absolutePath(requiredText(module, "sourceOutputDirectory")).toFile()));
    }

    List<PluginConfigurationImpl> pluginConfigurations = new ArrayList<>();
    JsonNode pluginNodes = root.path("pluginsConfiguration");
    if (pluginNodes.isArray()) {
      for (JsonNode pluginNode : (ArrayNode) pluginNodes) {
        pluginConfigurations.add(
            new PluginConfigurationImpl(
                requiredText(pluginNode, "fqPluginName"),
                DokkaConfiguration.SerializationFormat.valueOf(
                    requiredText(pluginNode, "serializationFormat")),
                requiredText(pluginNode, "values")));
      }
    }

    return new DokkaConfigurationImpl(
        requiredText(root, "moduleName"),
        optionalText(root, "moduleVersion"),
        outputDirectory.toFile(),
        optionalFile(root, "cacheRoot"),
        root.path("offlineMode").asBoolean(),
        List.of(),
        new ArrayList<>(files(root.path("pluginsClasspath"))),
        pluginConfigurations,
        modules,
        root.path("failOnWarning").asBoolean(),
        false,
        root.path("suppressObviousFunctions").asBoolean(true),
        files(root.path("includes")),
        root.path("suppressInheritedMembers").asBoolean(),
        root.path("finalizeCoroutines").asBoolean(true));
  }

  private static Set<File> files(JsonNode nodes) {
    Set<File> files = new LinkedHashSet<>();
    if (nodes.isArray()) {
      for (JsonNode node : (ArrayNode) nodes) {
        files.add(absolutePath(node.asText()).toFile());
      }
    }
    return files;
  }

  private static void absolutizeArray(ObjectNode node, String field) {
    JsonNode values = node.path(field);
    if (!values.isArray()) {
      return;
    }
    ArrayNode absoluteValues = OBJECT_MAPPER.createArrayNode();
    for (JsonNode value : (ArrayNode) values) {
      absoluteValues.add(absolutePath(value.asText()).toString());
    }
    node.set(field, absoluteValues);
  }

  private static void absolutizeField(ObjectNode node, String field) {
    node.put(field, absolutePath(requiredText(node, field)).toString());
  }

  private static void absolutizeOptionalField(ObjectNode node, String field) {
    String value = optionalText(node, field);
    if (value != null && !value.isEmpty()) {
      node.put(field, absolutePath(value).toString());
    }
  }

  private static File optionalFile(ObjectNode node, String field) {
    String value = optionalText(node, field);
    return value == null || value.isEmpty() ? null : absolutePath(value).toFile();
  }

  private static String requiredText(JsonNode node, String field) {
    String value = optionalText(node, field);
    if (value == null || value.isEmpty()) {
      throw new IllegalArgumentException("Missing required Dokka manifest field: " + field);
    }
    return value;
  }

  private static String optionalText(JsonNode node, String field) {
    JsonNode value = node.get(field);
    return value == null || value.isNull() ? null : value.asText();
  }

  private static Path absolutePath(String path) {
    return Paths.get(path).toAbsolutePath().normalize();
  }

  private DokkaGeneratorRunner() {}
}
