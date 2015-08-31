#
#   Copyright 2015 Christoph Wehmeyer
#

import numpy as np
cimport numpy as np

cdef extern from "_dtram.h":
    void rc_dtram_set_lognu(
            double *log_nu_K_i, int *C_K_ij, int n_therm_states, int n_markov_states)
    void rc_dtram_lognu(
            double *log_nu_K_i, double *b_K_i, double *f_i, int *C_K_ij, int n_therm_states,
            int n_markov_states, double *scratch_M, double *new_log_nu_K_i)
    void rc_dtram_fi(
            double *log_nu_K_i, double *b_K_i, double *f_i, int *C_K_ij, int n_therm_states,
            int n_markov_states, double *scratch_TM, double *scratch_M, double *new_f_i)
    void rc_dtram_p(
            double *log_nu_K_i, double *b_K_i, double *f_i, int *C_K_ij, int n_therm_states,
            int n_markov_states, double *scratch_M, double *p_K_ij)
    void rc_dtram_fk(
            double *b_K_i, double *f_i, int n_therm_states, int n_markov_states,
            double *scratch_M, double *f_K)

def dtram_set_lognu(
        np.ndarray[double, ndim=2, mode="c"] log_nu_K_i not None,
        np.ndarray[int, ndim=3, mode="c"] C_K_ij not None):
    rc_dtram_set_lognu(
            <double*> np.PyArray_DATA(log_nu_K_i),
            <int*> np.PyArray_DATA(C_K_ij),
            log_nu_K_i.shape[0],
            log_nu_K_i.shape[1])

def dtram_lognu(
        np.ndarray[double, ndim=2, mode="c"] log_nu_K_i not None,
        np.ndarray[double, ndim=2, mode="c"] b_K_i not None,
        np.ndarray[double, ndim=1, mode="c"] f_i not None,
        np.ndarray[int, ndim=3, mode="c"] C_K_ij not None,
        np.ndarray[double, ndim=1, mode="c"] scratch_M not None,
        np.ndarray[double, ndim=2, mode="c"] new_log_nu_K_i not None):
    rc_dtram_lognu(
            <double*> np.PyArray_DATA(log_nu_K_i),
            <double*> np.PyArray_DATA(b_K_i),
            <double*> np.PyArray_DATA(f_i),
            <int*> np.PyArray_DATA(C_K_ij),
            log_nu_K_i.shape[0],
            log_nu_K_i.shape[1],
            <double*> np.PyArray_DATA(scratch_M),
            <double*> np.PyArray_DATA(new_log_nu_K_i))

def dtram_fi(
        np.ndarray[double, ndim=2, mode="c"] log_nu_K_i not None,
        np.ndarray[double, ndim=2, mode="c"] b_K_i not None,
        np.ndarray[double, ndim=1, mode="c"] f_i not None,
        np.ndarray[int, ndim=3, mode="c"] C_K_ij not None,
        np.ndarray[double, ndim=2, mode="c"] scratch_TM not None,
        np.ndarray[double, ndim=1, mode="c"] scratch_M not None,
        np.ndarray[double, ndim=1, mode="c"] new_f_i not None):
    rc_dtram_fi(
            <double*> np.PyArray_DATA(log_nu_K_i),
            <double*> np.PyArray_DATA(b_K_i),
            <double*> np.PyArray_DATA(f_i),
            <int*> np.PyArray_DATA(C_K_ij),
            log_nu_K_i.shape[0],
            log_nu_K_i.shape[1],
            <double*> np.PyArray_DATA(scratch_TM),
            <double*> np.PyArray_DATA(scratch_M),
            <double*> np.PyArray_DATA(new_f_i))

def dtram_p(
        np.ndarray[double, ndim=2, mode="c"] log_nu_K_i not None,
        np.ndarray[double, ndim=2, mode="c"] b_K_i not None,
        np.ndarray[double, ndim=1, mode="c"] f_i not None,
        np.ndarray[int, ndim=3, mode="c"] C_K_ij not None,
        np.ndarray[double, ndim=1, mode="c"] scratch_M not None,
        np.ndarray[double, ndim=3, mode="c"] p_K_ij not None
    ):
    rc_dtram_p(
            <double*> np.PyArray_DATA(log_nu_K_i),
            <double*> np.PyArray_DATA(b_K_i),
            <double*> np.PyArray_DATA(f_i),
            <int*> np.PyArray_DATA(C_K_ij),
            log_nu_K_i.shape[0],
            log_nu_K_i.shape[1],
            <double*> np.PyArray_DATA(scratch_M),
            <double*> np.PyArray_DATA(p_K_ij))

def dtram_fk(
        np.ndarray[double, ndim=2, mode="c"] b_K_i not None,
        np.ndarray[double, ndim=1, mode="c"] f_i not None,
        np.ndarray[double, ndim=1, mode="c"] scratch_M not None,
        np.ndarray[double, ndim=1, mode="c"] f_K not None
    ):
    rc_dtram_fk(
            <double*> np.PyArray_DATA(b_K_i),
            <double*> np.PyArray_DATA(f_i),
            b_K_i.shape[0],
            b_K_i.shape[1],
            <double*> np.PyArray_DATA(scratch_M),
            <double*> np.PyArray_DATA(f_K))
