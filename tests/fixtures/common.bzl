"""Common definitions used by test fixtures."""

# Fixture targets are analyzed by tests or consumed as test data. They should
# not be selected as runnable test entry points themselves.
FIXTURE_TAGS = [
    "manual",
    "notap",
]
