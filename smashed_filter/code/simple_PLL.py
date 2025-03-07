import numpy as np
import matplotlib.pyplot as plt

phase_in = 3.0
frequency_in = -0.20
alpha = .02
beta = np.sqrt(alpha)

num_samples = 400
phase_out = 0.0
frequency_out = 0.0

si = []
so = []
pe = []

for nn in range(num_samples):
    sig_in = np.exp(1j*phase_in)
    sig_out = np.exp(1j*phase_out)
    
    phase_error = np.angle(sig_in*np.conj(sig_out))
    
    frequency_out += alpha * phase_error
    phase_out += beta * phase_error

    phase_in += frequency_in
    phase_out += frequency_out
    
    si.append(sig_in)
    so.append(sig_out)
    pe.append(phase_error)

plt.plot(si)
plt.plot(so)
plt.show()
