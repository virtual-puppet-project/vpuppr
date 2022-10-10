"""
Builds all vpuppr extensions if they have an applicable build script
"""

from argparse import ArgumentParser, Namespace
import os
import sys
import platform
import importlib


WINDOWS: str = "windows"
LINUX: str = "linux"
OSX: str = "osx"


def _setup_extensions(ext_dir: str, args: Namespace) -> None:
    """
    Loop through every extension and, if there is a setup.py script available,
    execute their `setup` and `clean` methods.

    Every setup.py script is imported like an actual module, monkeypatched,
    reloaded, and then has its methods executed.

    I acknowledge that this is pretty weird.
    """

    first_import: bool = True
    initial_path = os.getcwd()

    def setup_print(text: str, **kwargs) -> None:
        print("{}: {}".format(dir_name, text), **kwargs)

    for dir_name in os.listdir(ext_dir):
        dir = "{}/{}".format(ext_dir, dir_name)
        if not os.path.isdir(dir):
            continue

        setup_path = "{}/setup.py".format(dir)
        if not os.path.isfile(setup_path):
            continue

        os.chdir(dir)

        sys.path.append(dir)

        if first_import:
            import setup
            first_import = False
        else:
            importlib.reload(setup)

        if not hasattr(setup, "setup"):
            raise Exception(
                "{} is missing method 'setup(dict)'".format(setup.__file__))
        if not hasattr(setup, "clean"):
            raise Exception(
                "{} is missing method 'clean(dict)'".format(setup.__file__))

        # Monkeypatch the print function for the module
        setattr(setup, "print", setup_print)

        print("Processing {}".format(dir_name))

        if args.clean:
            setup.clean(args)
        if args.setup:
            setup.setup(args)

        print("Finished processing {}".format(dir_name))

        sys.path.remove(dir)

        os.chdir(initial_path)


def main() -> None:
    repo_root: str = "{}/../".format(
        os.path.dirname(os.path.realpath(__file__)))
    if not os.path.isdir(repo_root):
        raise Exception("Could not find repo root")

    ext_dir: str = "{}/resources/extensions".format(repo_root)
    if not os.path.isdir(ext_dir):
        raise Exception("Could not find extension directory")

    parser = ArgumentParser()
    parser.add_argument(
        "--os", choices=[WINDOWS, LINUX, OSX], default="")
    parser.add_argument("--export", action="store_true")
    parser.add_argument("--clean", action="store_true")
    parser.add_argument("--setup", action="store_true")
    parser.add_argument("--no-pyinstaller", action="store_true")

    args: Namespace = parser.parse_args()

    if not args.os:
        args.os = platform.system()
        if args.os == "Windows":
            args.os = WINDOWS
        elif args.os == "Linux":
            args.os = LINUX
        elif args.os == "Darwin":
            args.os = OSX
        else:
            raise Exception("Unhandled OS: {}".format(args.os))

    _setup_extensions(ext_dir, args)


if __name__ == "__main__":
    main()
