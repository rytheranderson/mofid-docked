import argparse
import json
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

from run_mofid import cif2mofid

DEFAULT_OUTPUT_PATH = Path("Output")


def parse_args() -> argparse.ArgumentParser:
    """Parse command line arguments.

    Returns:
        Namespace with parsed command line arguments.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-C",
        "--cif",
        nargs="+",
        type=Path,
        required=True,
        help="The CIF to generate a MOF ID and associated data for.",
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
    for cif in args.cif:
        with TemporaryDirectory() as outdir:
            results.append(cif2mofid(cif, outdir))

    resp = results[0] if len(results) == 1 else results
    with args.out as outfile:
        outfile.write(json.dumps(resp, indent=4))


if __name__ == "__main__":
    main()
