# This file is part of thermotools.
#
# Copyright 2015 Computational Molecular Biology Group, Freie Universitaet Berlin (GER)
#
# thermotools is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

r"""
Python interface to the MBAR estimator's lowlevel functions.
"""

import numpy as _np
cimport numpy as _np
from thermotools import mbar

__all__ = ['update_therm_energies', 'normalize', 'get_conf_energies', 'get_biased_conf_energies', 'estimate']

cdef extern from "_mbar_direct.h":
    void _update_therm_weights(
        int *therm_state_counts, double *therm_weights, double *bias_weight_sequence,
        int n_therm_states, int seq_length, double *scratch_T, double *new_therm_weights)

def update_therm_weights(
    _np.ndarray[int, ndim=1, mode="c"] therm_state_counts not None,
    _np.ndarray[double, ndim=1, mode="c"] therm_weights not None,
    _np.ndarray[double, ndim=2, mode="c"] bias_weight_sequence not None,
    _np.ndarray[double, ndim=1, mode="c"] scratch_T not None,
    _np.ndarray[double, ndim=1, mode="c"] new_therm_weights not None):
    r"""
    Calculate the reduced thermodynamic free energies therm_energies
        
    Parameters
    ----------
    therm_state_counts : numpy.ndarray(shape=(T), dtype=numpy.float64)
        state counts in each of the T thermodynamic states
    therm_weights : numpy.ndarray(shape=(T), dtype=numpy.float64)
        probabilities of the T thermodynamic states
    bias_weight_sequence : numpy.ndarray(shape=(T, X), dtype=numpy.float64)
        bias weights in the T thermodynamic states for all X samples
    scratch_T : numpy.ndarray(shape=(T), dtype=numpy.float64)
        scratch array
    new_therm_weights : numpy.ndarray(shape=(T), dtype=numpy.float64)
        target array for the probabilities of the T thermodynamic states
    """
    _update_therm_weights(
        <int*> _np.PyArray_DATA(therm_state_counts),
        <double*> _np.PyArray_DATA(therm_weights),
        <double*> _np.PyArray_DATA(bias_weight_sequence),
        bias_weight_sequence.shape[0],
        bias_weight_sequence.shape[1],
        <double*> _np.PyArray_DATA(scratch_T),
        <double*> _np.PyArray_DATA(new_therm_weights))


def estimate(therm_state_counts, bias_energy_sequence, conf_state_sequence,
    maxiter=1000, maxerr=1.0E-8, therm_energies=None, call_back=None):
    r"""
    Estimate the (un)biased reduced free energies and thermodynamic free energies
        
    Parameters
    ----------
    therm_state_counts : numpy.ndarray(shape=(T), dtype=numpy.intc)
        numbers of samples in the T thermodynamic states
    bias_energy_sequence : numpy.ndarray(shape=(T, X), dtype=numpy.float64)
        reduced bias energies in the T thermodynamic states for all X samples
    maxiter : int
        maximum number of iterations
    maxerr : float
        convergence criterion based on absolute change in free energies
    therm_energies : numpy.ndarray(shape=(T), dtype=numpy.float64), OPTIONAL
        initial guess for the reduced free energies of the T thermodynamic states

    Returns
    -------
    therm_energies : numpy.ndarray(shape=(T), dtype=numpy.float64)
        reduced free energies of the T thermodynamic states
    """
    T = therm_state_counts.shape[0]
    therm_state_counts = therm_state_counts.astype(_np.intc)
    M = 1 + _np.max(conf_state_sequence)
    log_therm_state_counts = _np.log(therm_state_counts)
    if therm_energies is None:
        therm_energies = _np.zeros(shape=(T,), dtype=_np.float64)
        therm_weights = _np.ones(shape=(T,), dtype=_np.float64)
    else:
        therm_weights = _np.exp(-therm_energies)
    bias_weight_sequence = _np.exp(-bias_energy_sequence)
    old_therm_energies = therm_energies.copy()
    old_therm_weights = therm_weights.copy()
    scratch_M = _np.zeros(shape=(M,), dtype=_np.float64)
    scratch_T = _np.zeros(shape=(T,), dtype=_np.float64)
    stop = False
    for _m in range(maxiter):
        update_therm_weights(therm_state_counts, old_therm_weights, bias_weight_sequence, scratch_T, therm_weights)
        if call_back is not None:
            error = _np.max(_np.abs((therm_weights - old_therm_weights)) / _np.abs(therm_weights))
            call_back(iteration=_m, therm_energies=therm_energies, old_therm_energies=old_therm_energies, error=error)
        if _np.max(_np.abs((therm_weights - old_therm_weights)) - maxerr * _np.abs(therm_weights)) < 0:
            stop = True
        else:
            old_therm_weights[:] = therm_weights[:]
        if stop:
            break
    therm_energies = -_np.log(therm_weights)
    conf_energies, biased_conf_energies = mbar.get_conf_energies(
        log_therm_state_counts, therm_energies, bias_energy_sequence, conf_state_sequence, scratch_T, M)
    #normalize(log_therm_state_counts, bias_energy_sequence, scratch_M, therm_energies, conf_energies, biased_conf_energies)
    return therm_energies, conf_energies, biased_conf_energies