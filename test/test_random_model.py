from __future__ import absolute_import
import unittest
from six.moves import range

import numpy as np
import msmtools
import thermotools.tram as tram
import thermotools.tram_direct as tram_direct
import sys

def tower_sample(distribution):
    cdf = np.cumsum(distribution)
    rnd = np.random.rand() * cdf[-1]
    return np.searchsorted(cdf, rnd)

def T_matrix(energy):
    n = energy.shape[0]
    metropolis = energy[np.newaxis, :] - energy[:, np.newaxis]
    metropolis[(metropolis < 0.0)] = 0.0
    selection = np.zeros((n,n))
    selection += np.diag(np.ones(n-1)*0.5,k=1)
    selection += np.diag(np.ones(n-1)*0.5,k=-1)
    selection[0,0] = 0.5
    selection[-1,-1] = 0.5
    metr_hast = selection * np.exp(-metropolis)
    for i in range(metr_hast.shape[0]):
        metr_hast[i, i] = 0.0
        metr_hast[i, i] = 1.0 - metr_hast[i, :].sum()
    return metr_hast

def draw_transition_counts(transition_matrices, n_samples, x0):
    """generates a discrete Markov chain"""
    count_matrices = np.zeros(shape=transition_matrices.shape, dtype=np.intc)
    conf_state_sequence = np.zeros(shape=(transition_matrices.shape[0]*(n_samples+1),), dtype=np.intc)
    state_counts = np.zeros(shape=transition_matrices.shape[0:2], dtype=np.intc)
    h = 0
    for K in range(transition_matrices.shape[0]):
        x = x0
        state_counts[K, x] += 1
        conf_state_sequence[h] = x
        h += 1
        for s in range(n_samples):
            x_new = tower_sample(transition_matrices[K, x, :])
            count_matrices[K, x, x_new] += 1
            x = x_new
            state_counts[K, x] += 1
            conf_state_sequence[h] = x
            h += 1
    return count_matrices, conf_state_sequence, state_counts

class TestRandom(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        n_therm_states = 4
        n_conf_states = 4
        n_samples = 10000

        cls.bias_energies = np.zeros(shape=(n_therm_states, n_conf_states), dtype=np.float64)
        cls.T = np.zeros(shape=(n_therm_states, n_conf_states, n_conf_states), dtype=np.float64)
        while True:
            # generate two random stionary distributions
            for k in range(n_therm_states):
                cls.bias_energies[k,:] = -np.log(np.random.rand(n_conf_states))
                if k>0:
                    cls.bias_energies[k,:] += np.random.rand()

            # generate transition matrices
            for k in range(n_therm_states):
                cls.T[k,:,:] = T_matrix(cls.bias_energies[k,:])

            cls.count_matrices, cls.conf_state_sequence, cls.state_counts = draw_transition_counts(cls.T, n_samples, 0)

            if msmtools.analysis.is_connected(cls.count_matrices.sum(axis=0), directed=True):
                break

        cls.bias_energies_sh = cls.bias_energies - cls.bias_energies[0,:]
        cls.bias_energies_sh = np.ascontiguousarray(cls.bias_energies_sh[:,cls.conf_state_sequence])

    def test_tram(self):
        biased_conf_energies, conf_energies, therm_energies, log_lagrangian_mult, error_history, logL_history = tram.estimate(
            self.count_matrices, self.state_counts, self.bias_energies_sh, self.conf_state_sequence,
            maxiter=1000000, maxerr=1.0E-10, lll_out=10)
        transition_matrices = tram.estimate_transition_matrices(
            log_lagrangian_mult, biased_conf_energies, self.count_matrices, None)

        # check expectations (do a trivial test: recompute conf_energies with different functions)
        mu = np.zeros(shape=self.conf_state_sequence.shape[0], dtype=np.float64)
        tram.get_pointwise_unbiased_free_energies(log_lagrangian_mult, biased_conf_energies,
            self.count_matrices, self.bias_energies_sh, self.conf_state_sequence, self.state_counts,
            None, None, mu)
        pmf = np.zeros(shape=4, dtype=np.float64)
        tram.get_unbiased_user_free_energies(mu, self.conf_state_sequence, pmf)
        assert np.allclose(pmf, conf_energies)

        biased_conf_energies -= np.min(biased_conf_energies)
        bias_energies =  self.bias_energies - np.min(self.bias_energies)

        nz = np.where(self.state_counts>0)
        assert not np.any(np.isinf(log_lagrangian_mult[nz]))
        assert np.allclose(biased_conf_energies, bias_energies, atol=0.1)
        assert np.allclose(transition_matrices, self.T, atol=0.1)
        assert np.all(logL_history[-1]+1.E-5>=np.array(logL_history[0:-1]))

    def test_tram_direct(self):
        biased_conf_energies, conf_energies, therm_energies, log_lagrangian_mult, error_history, logL_history = tram_direct.estimate(
            self.count_matrices, self.state_counts, self.bias_energies_sh, self.conf_state_sequence,
            maxiter=1000000, maxerr=1.0E-10, lll_out=10)
        transition_matrices = tram.estimate_transition_matrices(
            log_lagrangian_mult, biased_conf_energies, self.count_matrices, None)

        biased_conf_energies -= np.min(biased_conf_energies)
        bias_energies =  self.bias_energies - np.min(self.bias_energies)

        nz = np.where(self.state_counts>0)
        assert not np.any(np.isinf(log_lagrangian_mult[nz]))
        assert np.allclose(biased_conf_energies, bias_energies, atol=0.1)
        assert np.allclose(transition_matrices, self.T, atol=0.1)
        assert np.all(logL_history[-1]+1.E-5>=logL_history[0:-1])


if __name__ == "__main__":
    unittest.main()
