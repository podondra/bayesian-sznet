import h5py
import numpy as np
from spectres import spectres


LOGLAMMIN, LOGLAMMAX = 3.5818, 3.9633
N_FEATURES = 512
EPS = 0.0005
N_VAL, N_TEST = 50000, 50000


with h5py.File("data/dr12q_superset.hdf5", "r+") as datafile:
    ids = datafile["id"][:]
    fluxes = datafile["flux"][:]
    z_vi = datafile["z_vi"][:]
    z_pipe = datafile["z_pipe"][:]

    # resample
    n_waves = fluxes.shape[1]
    loglam = np.linspace(LOGLAMMIN, LOGLAMMAX, n_waves)
    # EPS else will get nans in output
    new_loglam = np.linspace(LOGLAMMIN + EPS, LOGLAMMAX - EPS, N_FEATURES)
    X = spectres(
            new_loglam, loglam, fluxes,
            verbose=True).astype(np.float32, copy=False)
    X_dset = datafile.create_dataset("X", data=X)

    # split into training, validation and test set
    # (sizes almost according to ILSVRC)
    # seed from random.org
    rng = np.random.default_rng(seed=66)
    n = ids.shape[0]
    rnd_idx = rng.permutation(n)
    n_tr = n - N_VAL - N_TEST
    idx_tr = rnd_idx[:n_tr]
    idx_va = rnd_idx[n_tr:n_tr + N_VAL]
    idx_te = rnd_idx[n_tr + N_VAL:]

    for name, idx in [("tr", idx_tr), ("va", idx_va), ("te", idx_te)]:
        datafile.create_dataset("id_" + name, data=ids[idx, :])
        datafile.create_dataset("X_" + name, data=X[idx])
        datafile.create_dataset("z_vi_" + name, data=z_vi[idx])
        datafile.create_dataset("z_pipe_" + name, data=z_pipe[idx])