r"""
thermotools is a lowlevel implementation toolbox for the analyis of free energy calculations
"""

from .lse import logsumexp, logsumexp_pair
from .wham import wham_fi, wham_fk, wham_normalize
from .dtram import dtram_set_lognu, dtram_lognu, dtram_fi, dtram_pk, dtram_p, dtram_fk
from ._version import get_versions

__author__ = "Christoph Wehmeyer"
__copyright__ = "Copyright 2015 Computational Molecular Biology Group, FU-Berlin"
__version__ = get_versions()['version']
__email__ = "christoph.wehmeyer AT fu-berlin DOT de"

del get_versions
