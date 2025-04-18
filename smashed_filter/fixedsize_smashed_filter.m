clear all;

M = 300;
K = 250; %300:-10:10; % 200;
runs = 1;
mse_orth = zeros(size(K, 2), runs);
mse_direct = zeros(size(K, 2), runs);
mse_b = zeros(size(K, 2), runs);
miss_class_runs = zeros(size(K, 2), runs);
miss_class_admm_runs = zeros(size(K, 2), runs);

for i=1:size(K)
    for j=1:runs
        edges = [50, 120, 170, 192, 220, 244, 256, 300] ;
        levels = [400,  0 , 300, 0, 0, 0, 800, 0];
        idxs = zeros(1, M)  ;
        idxs(edges(1: end-1)+1) = 1 ;
        g = levels(cumsum(idxs)+1);
        sigma_squared = [1, 10, 100, 1000];
        noise = normrnd(0, 1, [1, M]);
        max_not_in_positions = 0;
        
        ge = g + noise;
        
        F = LehmerMatrix(M);
        [L, U] = lu(F);
        I = eye(M);
        D = inv(L);
        
        h = cumsum(g)';
        
        he = cumsum(ge)';
        
        A = normrnd(0, 1/(K(i)), [K(i), M]);
        
        y = A*g';
        
        orth_templates = zeros(M, K(i));
        direct_templates = zeros(M, K(i));
        b = zeros(1, M);
        c = zeros(1, M);
                 
        for k=1:M
            orth_templates(k, :) = (A*A')\A*L(k,:)';
            direct_templates(k, :) = A*L(k, :)';
            b(k) = (M/K(i))*(y'*orth_templates(k,:)');
            c(k) = K(i)*(y'*direct_templates(k,:)');
        end
        
        class = zeros(1, M);
        miss_class = zeros(1, M);
        
        ghat = L\b';
        ahat = F\b';
        thresh = 0.2*max(ghat);
        
        plot(1:M, ghat, 'b', 1:M, g, 'r')
        
        % Find k biggest values of ahat
        
        [sorted_ahat, inds] = sort(abs(ahat), 'descend');
        
        k = 15;
        
        ahat_big = inds(1:k);
        
        for ii = 1:M
            if ismember(ii, ahat_big);
                ii;
            else
                ahat(ii) = 0;
            end
        end
        
        % take the average of ghat between these vaules
        piece_mean = zeros(1,k);
        piece_var = zeros(1,k);
        threshths = zeros(1,k);
        inds = [1, ahat_big', 300];
        inds = sort(inds);
        for l=1:k
            piece = ghat(inds(l):inds(l+1))';
            piece_mean(l) = mean(piece);
            piece_var(l) = var(piece,1);
            threshths(l) = (1.96*piece_var(l))/sqrt(length(piece));
        end
        
        estimate = zeros(1, M);
        threshest = zeros(1, M);
        
        for ii=1:k
            for jj = inds(ii):inds(ii+1)
                estimate(jj) = piece_mean(ii);
                threshest(jj) = threshths(ii);
            end
        end
        
        errors = zeros(1,M);
        
%         
%         
%         for ii = 1:M
%             if estimate(ii) < thresh
%                 estimate(ii) = 0;
%             else
%                 estimate(ii) = 1;
%             end
%             
%             if g(ii) < 100
%                 g(ii) = 0;
%             else
%                 g(ii) = 1;
%             end
%       
%             if estimate(ii) == g(ii)
%                 miss_class(ii) = 0;
%             else
%                 miss_class(ii) = 1;
%             end
%         end
        
        %count the # of places estimae is 1 when g isn't
        miss_class_runs(i,j) = length(find(miss_class))/M;
    end
end

figure
plot(1:M, estimate, 'b', 1:M, g, 'r')