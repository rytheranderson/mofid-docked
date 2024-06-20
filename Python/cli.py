import argparse
import io
import json
import sys
from contextlib import redirect_stderr
from pathlib import Path
from tempfile import TemporaryDirectory

from mofid.run_mofid import cif2mofid  # type:ignore[import-untyped]


def parse_args() -> argparse.ArgumentParser:
    """Parse command line arguments.

    Returns:
        Namespace with parsed command line arguments.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-C",
        "--cifs",
        nargs="+",
        type=Path,
        help="The CIFs to generate MOF IDs and associated data for.",
    )
    parser.add_argument(
        "-O",
        "--out",
        type=argparse.FileType("w"),
        default=sys.stdout,
    )
    return parser


def main() -> None:
    """Do the ID getting thing."""
    args = parse_args().parse_args()

    results = []
    for cif in args.cifs:
        with TemporaryDirectory() as outdir:
            with redirect_stderr(io.StringIO()) as err_redirect:
                res = cif2mofid(cif, outdir)
                # Capture warnings sent to stderr, add to the results dict
                res["captured_stderr"] = err_redirect.getvalue().splitlines()
                results.append(res)

    resp = results[0] if len(results) == 1 else results
    with args.out as outfile:
        outfile.write(json.dumps(resp, indent=4))


if __name__ == "__main__":
    main()
