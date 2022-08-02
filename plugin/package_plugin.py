import dotbot
import sys

sys.path += ["./plugin/"]

from package import parse_args, process, logger


class PackageManager(dotbot.Plugin):
    """
    Install packages from Yaml File
    """

    _directive = "package"

    def can_handle(self, directive):
        return directive == self._directive

    def handle(self, directive, data):
        assert directive == self._directive
        try:
            process(parse_args([""]), data)
            return True
        except Exception as e:
            logger.error(repr(e))
            return False
