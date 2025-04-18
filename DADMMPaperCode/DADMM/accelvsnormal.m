clear all;
close all;

%randn('seed', 0);
%rand('seed',0);

direct_current = pwd;                                      % Current
direct_networks = '/home/tk12098/Documents/MATLAB/DADMMPaperCode/GenerateData/Networks';           % Networks
% Compressed Sensing Data
%direct_data = '/home/tk12098/Documents/MATLAB/DADMMPaperCode/GenerateData/ProblemData/CompressedSensing';
direct_DADMM = '/home/tk12098/Documents/MATLAB/DADMMPaperCode/DADMM';

% =========================================================================


% =========================================================================

% Selecting the network

%cd(direct_networks);
load Nets_50_nodes.mat;     % File with randomly generated networks
%cd(direct_current);

% Select the network number: 1 to 7
net_num = 4 ;
%net_num = gengeonet(50, 0.25);

Adj = Networks{net_num}.Adj;                   % Adjacency matrix
partition_colors = Networks{net_num}.Partition;% Color partition of network

P = length(Adj);                               % Number of nodes

% Construct the cell neighbors, where neighbors{p} is a vector with the
% neighbors of node p
neighbors = cell(P,1);

for p = 1 : P
    neighbors{p} = find(Adj(p,:));
end

Inc = adj2inc(Adj);
w_local_degree = local_degree(Adj);
%weights = construct_weight_mtx(w_local_degree, Adj);
%Create struct with network information
vars_network = struct('P', {P}, ...
    'neighbors', {neighbors}, ...
    'W', {w_local_degree}, ...
    'partition_colors', {partition_colors} ...
    );

L = 200;
m = 50;

positions = randi(L,[1,5]);%generate random spikes for signal

Tx_psd = zeros(1,L); %Tx PSD
Tx_psd(positions) = 1000;

S = randn(m,L);
A_BP = S;
sigma = 10^(-10/20);
eta = randn(1,m)/m;
noise_sum = sum(eta);
b = A_BP*Tx_psd'+ sigma*eta';

lambda = sqrt(2*log(size(Tx_psd,2)));

max_iter = 5000;
error_i_accel = zeros(1, max_iter+1);
path = zeros(100, L);

max_eig = max(abs(eig(A_BP'*A_BP)));

rho = 1/max_eig;
rho = nthroot(rho, 3);

if mod(m,P) ~= 0
    error('m divided by P must be integer');
end
m_p = m/P; 

% Create struct with problem data used in 'minimize_quad_prog_plus_l1_BB'
vars_prob = struct('handler_GPSR', @GPSR_BB, ...
    'A_BPDN', {A_BP}, ...
    'b_BPDN', {b}, ...
    'm_p', {m_p}, ...
    'P', {P}, ...
    'beta', {lambda*max_eig}, ...
    'relax', {1}...
    );
% =========================================================================

% =========================================================================
% Execute D-ADMM

% Optional input
ops = struct('rho', {rho}, ...
    'max_iter', {max_iter}, ...
    'x_opt', {Tx_psd'}, ...
    'eps_opt', {1e-2}, ...
    'turn_off_eps', {0} ...
    );

cd(direct_DADMM);
tic
[W, Y, vars_prob, ops_out_admm] = DADMM(L, vars_prob, vars_network, ops);
toc
cd(direct_current);

% =========================================================================

% =========================================================================
% Execute D-ADMM

% % Create struct with problem data used in 'minimize_quad_prog_plus_l1_BB'
vars_prob_lo = struct('handler_GPSR', @GPSR_BB, ...
    'A_BPDN', {A_BP}, ...
    'b_BPDN', {b}, ...
    'm_p', {m_p}, ...
    'P', {P}, ...
    'beta', {500*lambda*max_eig}, ...
    'relax', {1}...
    );

% Optional input
ops = struct('rho', {rho}, ...
    'max_iter', {max_iter}, ...
    'x_opt', {Tx_psd'}, ...
    'eps_opt', {1e-2}, ...
    'turn_off_eps', {0} ...
    );

cd(direct_DADMM);
tic
[X, Z, vars_prob, ops_out_lo] = DADMM_lo(L, vars_prob_lo, vars_network, ops);
toc
cd(direct_current);

% % =========================================================================

% =========================================================================

% vars_prob_amp = struct('handler_GPSR', @GPSR_BB, ...
%     'A_BPDN', {A_BP}, ...
%     'b_BPDN', {b}, ...
%     'Template', {Tx_psd}, ...
%     'm_p', {m_p}, ...
%     'P', {P}, ...
%     'beta', {10*lambda*max_eig}, ...
%     'relax', {1}...
%     );
% 
% % Optional input
% ops = struct('rho', {rho}, ...
%     'max_iter', {max_iter}, ...
%     'x_opt', {Tx_psd'}, ...
%     'eps_opt', {1e-2}, ...
%     'turn_off_eps', {0} ...
%     );
% 
% cd(direct_DADMM);
% tic
% [X, Z, vars_prob_amp, ops_out_amp] = DADMM_AMP(L, vars_prob_amp, vars_network, ops);
% toc
% cd(direct_current);

%============================================================================

% Print results

iterations = ops_out_lo.iterations;
stop_crit = ops_out_lo.stop_crit;
error_lo = ops_out_lo.error_iterations_x;
error_admm = ops_out_admm.error_iterations_z;

solution = spgl1(A_BP, b, 0, 0.0001, []);

fprintf('||A_BP*solution-b|| = %E\n', norm(A_BP*solution-b));
fprintf('norm(solution,1) = %E\n', norm(solution,1));

figure;clf;
semilogy(1:iterations,error_admm(1:iterations), 'b', 1:iterations,error_lo(1:iterations), 'r');
legend('Normal', 'Accel');
title('error\_{iterations_z}');

figure;clf;
plot(1:iterations,error_admm(1:iterations), 'b', 1:iterations,error_lo(1:iterations), 'r');
legend('Normal', 'Accel');
title('error\_{iterations_z}');

figure
plot(1:L, Z{1}, 'r', 1:L, solution, 'b')
title('Accel')

figure
plot(1:L, W{1}, 'r', 1:L, solution, 'b')
title('DADMM')

figure
subplot(2,1,1)
plot(1:L, W{1}, 'b')
title('x_{DADMM}')
subplot(2,1,2)
plot(1:L, Z{1}, 'r')
title('x_{DBP}')
