% CaseStudyA_V3  Six retirement withdrawal strategies with shared Monte Carlo paths.
%
% Strategies: 4% Rule, Guardrails, % of Portfolio, Guyton-Klinger,
%             Drawdown (re-amortization to selected end age), and Endowment.
%
% Example: CaseStudyA_V3('sim',10000,'mu',0.06,'sigma',0.12,'infl',0.02)
%
% Cashflow convention (same as the uploaded model): annual market return
% is credited before that year's withdrawal. Withdrawals cannot exceed the
% available balance. All figures are nominal dollars; no taxes or fees.
%
% GUYTON-KLINGER is a spending-rule implementation, not a replication of
% Guyton-Klinger's multi-asset portfolio-management/sale-order rules.
% ENDOWMENT is a household adaptation of the Yale 80/20 smoothing method;
% it uses the current year's beginning balance instead of Yale's lagged
% valuations and omits Yale's endowment-specific taxes/administration.
function h = CaseStudyA_V3(varargin)    
    %% Defaults and name-value inputs
    P0_default  = 1e6;
    age_default = 65;
    end_age_default = 100;
    thr_default = [0 250000 500000 1000000];
    
    params = struct( ...
        'mu',0.06, 'sigma',0.12, 'infl',0.02, 'sim',10000, 'rngSeed',1, ...
        'R0',0.04, 'L',0.03, 'U',0.05, 'uUp',0.10, 'uDown',0.10, ...
        'alpha',0.05, ...
        'gkR0',0.055, 'gkBand',0.20, 'gkAdjust',0.10, 'gkFreeze',15, ...
        'drawRate',0.04, 'drawBequest',0, ...
        'endoRate',0.0525, 'endoWeight',0.80, 'endoFloor',0.04, 'endoCeil',0.065);
    
    if mod(numel(varargin),2) ~= 0
        error('Name-value pairs expected.');
    end
    for k = 1:2:numel(varargin)
        nm = char(varargin{k});
        if isfield(params,nm)
            params.(nm) = varargin{k+1};
        else
            warning('Unknown option "%s" ignored.',nm);
        end
    end
    
    rateNames = {'R0','L','U','uUp','uDown','alpha','gkR0', ...
        'gkBand','gkAdjust','drawRate','endoRate','endoWeight', ...
        'endoFloor','endoCeil'};
    for k = 1:numel(rateNames)
        nm = rateNames{k};
        params.(nm) = asFraction(params.(nm));
    end
    validateattributes(params.mu,{'numeric'},{'scalar','finite'});
    validateattributes(params.sigma,{'numeric'},{'scalar','nonnegative','finite'});
    validateattributes(params.infl,{'numeric'},{'scalar','>=',-0.99,'finite'});
    validateattributes(params.sim,{'numeric'},{'scalar','integer','positive'});
    validateattributes(params.drawBequest,{'numeric'},{'scalar','nonnegative','finite'});
    validateattributes(params.gkFreeze,{'numeric'},{'scalar','integer','nonnegative'});
    if params.endoFloor > params.endoCeil
        error('endoFloor must not exceed endoCeil.');
    end
    if params.L > params.U
        error('Guardrails lower L must not exceed upper U.');
    end
    if ~isempty(params.rngSeed)
        rng(params.rngSeed,'twister');
    end
    
    labels = {'4% Rule','Guardrails','% of Portfolio', ...
        'Guyton-Klinger','Drawdown','Endowment'};
    modes = {'fixed4','guard','pct','gk','draw','endo'};
    colors = [0.0000 0.4470 0.7410; ...
              0.8500 0.3250 0.0980; ...
              0.4660 0.6740 0.1880; ...
              0.4940 0.1840 0.5560; ...
              0.3010 0.7450 0.9330; ...
              0.6350 0.0780 0.1840];
    K = numel(labels);
    
    %% Main window
    fig = uifigure('Name','Retirement Monte Carlo - Six Strategies', ...
        'Position',[100 100 1500 850]);
    main = uigridlayout(fig,[1 2], ...
        'ColumnWidth',{395,'1x'}, 'RowHeight',{'1x'}, ...
        'Padding',10,'ColumnSpacing',10);
    
    pnl = uipanel(main,'Title','Inputs','FontWeight','bold','Scrollable','on');
    pnl.Layout.Row = 1; pnl.Layout.Column = 1;
    gL = uigridlayout(pnl,[28 2], ...
        'RowHeight',repmat({36},1,28), ...
        'ColumnWidth',{185,'1x'}, ...
        'Padding',10,'RowSpacing',7,'ColumnSpacing',10, 'Scrollable', 'on');
    
    % General inputs
    uilabel(gL,'Text','Starting Portfolio ($):','HorizontalAlignment','right');
    inP0 = uieditfield(gL,'numeric','Value',P0_default,'Limits',[0 Inf]);
    uilabel(gL,'Text','Start Age:','HorizontalAlignment','right');
    inAge = uieditfield(gL,'numeric','Value',age_default,'Limits',[0 150]);
    uilabel(gL,'Text','End Age:','HorizontalAlignment','right');
    inEndAge = uieditfield(gL,'numeric','Value',end_age_default, ...
        'Limits',[0 150],'RoundFractionalValues','on', ...
        'Tooltip','All strategies and Monte Carlo paths stop at this age');
    uilabel(gL,'Text','Thresholds ($):','HorizontalAlignment','right');
    inThresh = uieditfield(gL,'text','Value','0, 250000, 500000, 1000000', ...
        'Tooltip','Comma-separated ending balance thresholds');
    
    addHeader(gL,'4% Rule');
    uilabel(gL,'Text','Initial rate R0:','HorizontalAlignment','right');
    inR0 = rateInput(gL,params.R0,'Initial withdrawal as a fraction of original portfolio');
    
    addHeader(gL,'Guardrails (existing method)');
    uilabel(gL,'Text','Lower L:','HorizontalAlignment','right');
    inL = rateInput(gL,params.L,'If withdrawal/portfolio < L, increase spending');
    uilabel(gL,'Text','Upper U:','HorizontalAlignment','right');
    inU = rateInput(gL,params.U,'If withdrawal/portfolio > U, decrease spending');
    uilabel(gL,'Text','Raise fraction:','HorizontalAlignment','right');
    inUup = rateInput(gL,params.uUp,'Raise spending by this fraction');
    uilabel(gL,'Text','Cut fraction:','HorizontalAlignment','right');
    inUdown = rateInput(gL,params.uDown,'Cut spending by this fraction');
    
    addHeader(gL,'% of Portfolio');
    uilabel(gL,'Text','Annual fraction alpha:','HorizontalAlignment','right');
    inAlpha = rateInput(gL,params.alpha,'Withdraw this fraction of start-of-year balance');
    
    addHeader(gL,'Guyton-Klinger (decision rules)');
    uilabel(gL,'Text','Initial GK rate:','HorizontalAlignment','right');
    inGkR0 = rateInput(gL,params.gkR0,'Initial withdrawal rate, e.g. 0.055');
    uilabel(gL,'Text','Guardrail +/- fraction:','HorizontalAlignment','right');
    inGkBand = rateInput(gL,params.gkBand,'Relative distance from initial rate, e.g. 0.20');
    uilabel(gL,'Text','Raise/cut fraction:','HorizontalAlignment','right');
    inGkAdjust = rateInput(gL,params.gkAdjust,'Relative spending adjustment, e.g. 0.10');
    uilabel(gL,'Text','Final years (no cut):','HorizontalAlignment','right');
    inGkFreeze = uieditfield(gL,'numeric','Value',params.gkFreeze, ...
        'Limits',[0 100], ...
        'Tooltip','Disable capital-preservation CUT in the final N years');
    
    addHeader(gL,'Drawdown (spend down by selected end age)');
    uilabel(gL,'Text','Assumed annual return:','HorizontalAlignment','right');
    inDrawRate = rateInput(gL,params.drawRate,'Rate used for yearly re-amortization; not realized returns');
    uilabel(gL,'Text','Target bequest ($):','HorizontalAlignment','right');
    inDrawBequest = uieditfield(gL,'numeric','Value',params.drawBequest, ...
        'Limits',[0 Inf], ...
        'Tooltip','Desired nominal balance at selected end age; 0 deliberately spends down');
    
    addHeader(gL,'Endowment (smoothed spending)');
    uilabel(gL,'Text','Target payout rate:','HorizontalAlignment','right');
    inEndoRate = rateInput(gL,params.endoRate,'Long-run target annual percentage');
    uilabel(gL,'Text','Prior-spending weight:','HorizontalAlignment','right');
    inEndoWeight = rateInput(gL,params.endoWeight,'Weight on last withdrawal raised with inflation');
    uilabel(gL,'Text','Payout floor:','HorizontalAlignment','right');
    inEndoFloor = rateInput(gL,params.endoFloor,'Minimum of beginning portfolio balance');
    uilabel(gL,'Text','Payout ceiling:','HorizontalAlignment','right');
    inEndoCeil = rateInput(gL,params.endoCeil,'Maximum of beginning portfolio balance');
    
    autoRun = uicheckbox(gL,'Text','Auto-run on change','Value',false);
    autoRun.Layout.Column = [1 2];
    runBtn = uibutton(gL,'Text','Run Simulation','FontWeight','bold');
    runBtn.Layout.Column = [1 2];
    
    %% Plots and text
    right = uigridlayout(main,[2 1], ...
        'RowHeight',{'5x','2x'},'Padding',0,'RowSpacing',10);
    tg = uitabgroup(right); tg.Layout.Row = 1;
    tab1 = uitab(tg,'Title','Single Path');
    tab2 = uitab(tg,'Title',sprintf('%s Sims',formatInteger(params.sim)));
    g1 = uigridlayout(tab1,[2 2],'RowHeight',{'1x','1x'}, ...
        'ColumnWidth',{'1x','1x'},'Padding',6,'RowSpacing',12,'ColumnSpacing',12);
    g2 = uigridlayout(tab2,[2 2],'RowHeight',{'1x','1x'}, ...
        'ColumnWidth',{'1x','1x'},'Padding',6,'RowSpacing',12,'ColumnSpacing',12);
    
    ax_r_1 = uiaxes(g1);   title(ax_r_1,'Market Performance (one path)');
    ax_g_1 = uiaxes(g1);   title(ax_g_1,'Investment Gains (all strategies)');
    ax_w_1 = uiaxes(g1);   title(ax_w_1,'Annual Withdrawals');
    ax_bal_1 = uiaxes(g1); title(ax_bal_1,'Portfolio Balances');
    ax_r_mc = uiaxes(g2);   title(ax_r_mc,'Market Returns (10th-90th %)');
    ax_g_mc = uiaxes(g2);   title(ax_g_mc,'Investment Gains (10th-90th %)');
    ax_w_mc = uiaxes(g2);   title(ax_w_mc,'Withdrawals (10th-90th %)');
%    ax_bal_mc = uiaxes(g2); title(ax_bal_mc,'Ending Balances');
    allAxes = [ax_r_1 ax_g_1 ax_w_1 ax_bal_1 ax_r_mc ax_g_mc ax_w_mc... %ax_bal_mc
               ];
    for a = allAxes
        xlabel(a,'Year'); grid(a,'on');
    end
    ylabel(ax_r_1,'Return'); ylabel(ax_g_1,'Gains ($)');
    ylabel(ax_w_1,'Withdrawals ($)'); ylabel(ax_bal_1,'Balance ($)');
    ylabel(ax_r_mc,'Return'); ylabel(ax_g_mc,'Gains ($)');
    ylabel(ax_w_mc,'Withdrawals ($)');
%    ylabel(ax_bal_mc,'Ending Balance ($)'); xlabel(ax_bal_mc,'Strategy');
    
    outTxt = uitextarea(right,'Editable','off','FontName','Consolas');
    outTxt.Layout.Row = 2;
    setText(outTxt,'Run a simulation to see results...');
    
    % All input changes share the same callback.
    controls = {inP0,inAge,inEndAge,inThresh,inR0,inL,inU,inUup,inUdown,inAlpha, ...
        inGkR0,inGkBand,inGkAdjust,inGkFreeze,inDrawRate,inDrawBequest, ...
        inEndoRate,inEndoWeight,inEndoFloor,inEndoCeil};
    for k = 1:numel(controls)
        controls{k}.ValueChangedFcn = @(~,~)maybeAutoRun();
    end
    runBtn.ButtonPushedFcn = @runSim;
    
    % Expose handles to calling scripts, as in the original implementation.
    if nargout > 0
        h = struct();
        h.Fig = fig; h.Text = outTxt;
        h.Controls = struct('P0',inP0,'Age',inAge,'EndAge',inEndAge,'Thresh',inThresh, ...
            'R0',inR0,'L',inL,'U',inU,'Uup',inUup,'Udown',inUdown, ...
            'Alpha',inAlpha,'GkR0',inGkR0,'GkBand',inGkBand, ...
            'GkAdjust',inGkAdjust,'GkFreeze',inGkFreeze, ...
            'DrawRate',inDrawRate,'DrawBequest',inDrawBequest, ...
            'EndoRate',inEndoRate,'EndoWeight',inEndoWeight, ...
            'EndoFloor',inEndoFloor,'EndoCeil',inEndoCeil, ...
            'AutoRun',autoRun,'RunBtn',runBtn);
        h.Params = params;
        h.SinglePathAxes = struct('r',ax_r_1,'g',ax_g_1,'w',ax_w_1,'bal',ax_bal_1);
%        h.SimsAxes = struct('r',ax_r_mc,'g',ax_g_mc,'w',ax_w_mc,'bal',ax_bal_mc);
    end
    
    %% Callbacks
    function maybeAutoRun()
        if autoRun.Value
            runSim();
        end
    end

    function runSim(~,~)
        P0 = inP0.Value;
        age0 = round(inAge.Value);
        endAge = round(inEndAge.Value);
        years = max(0,endAge-age0);
        if years == 0
            setText(outTxt,'End Age must be greater than Start Age to simulate withdrawals.');
            return;
        end

        p = params;
        rateHandles = {inR0,inL,inU,inUup,inUdown,inAlpha, ...
            inGkR0,inGkBand,inGkAdjust,inDrawRate, ...
            inEndoRate,inEndoWeight,inEndoFloor,inEndoCeil};
        for j = 1:numel(rateNames)
            nm = rateNames{j};
            p.(nm) = asFraction(rateHandles{j}.Value);
            rateHandles{j}.Value = p.(nm);
        end
        p.gkFreeze = round(inGkFreeze.Value);
        p.drawBequest = inDrawBequest.Value;
        if p.L > p.U
            setText(outTxt,'Input error: Guardrails lower L must not exceed upper U.');
            return;
        end
        if p.endoFloor > p.endoCeil
            setText(outTxt,'Input error: Endowment payout floor must not exceed ceiling.');
            return;
        end
        thr = sscanf(strrep(inThresh.Value,',',' '),'%f');
        if isempty(thr), thr = thr_default; end
        thr = sort(unique(max(0,reshape(thr,1,[]))));

        % Common random numbers: each method sees the same market outcomes.
        % Returns cannot be worse than -100%.
        r1 = max(-1,p.mu+p.sigma*randn(1,years));
        bal1 = cell(1,K); with1 = cell(1,K); gain1 = cell(1,K);
        for k = 1:K
            [bal1{k},with1{k},gain1{k}] = simulate_path(P0,r1,p,modes{k});
        end

        cla(ax_r_1);
        plot(ax_r_1,1:years,r1,'-o','LineWidth',1.4);
        ylim(ax_r_1,autoY(r1));
        plotMulti(ax_g_1,1:years,gain1,labels,colors,'Investment Gains');
        plotMulti(ax_w_1,1:years,with1,labels,colors,'Annual Withdrawals');
        plotMulti(ax_bal_1,0:years,bal1,labels,colors,'Portfolio Balances');

        simN = p.sim;
        Rm = max(-1,p.mu+p.sigma*randn(simN,years));
        balMat = cell(1,K); withMat = cell(1,K);
        gainMat = cell(1,K); reqMat = cell(1,K);
        for k = 1:K
            balMat{k} = zeros(simN,years+1);
            withMat{k} = zeros(simN,years);
            gainMat{k} = zeros(simN,years);
            reqMat{k} = zeros(simN,years);
        end
        for s = 1:simN
            rpath = Rm(s,:);
            for k = 1:K
                [b,w,g,req] = simulate_path(P0,rpath,p,modes{k});
                balMat{k}(s,:) = b;
                withMat{k}(s,:) = w;
                gainMat{k}(s,:) = g;
                reqMat{k}(s,:) = req;
            end
        end

        cla(ax_r_mc); hold(ax_r_mc,'on');
        [medR,loR,hiR] = bands_from_matrix(Rm);
        fillBand(ax_r_mc,1:years,loR,hiR,[.5 .5 .5],.22,'10-90% band');
        plot(ax_r_mc,1:years,medR,'k','LineWidth',1.8,'DisplayName','Median');
        legend(ax_r_mc,'Location','best');
        plotMultiBands(ax_g_mc,1:years,gainMat,labels,colors,'Gains - Monte Carlo');
        plotMultiBands(ax_w_mc,1:years,withMat,labels,colors,'Withdrawals - Monte Carlo');

        endBal = zeros(simN,K);
        for k = 1:K
            endBal(:,k) = balMat{k}(:,end);
        end

        % COMMENTED OUT the logic for the 'Ending Balance' violin graph
        % contents.
        % The graph itself was COMMENTED OUT above.
%        violin_on_uiaxes(ax_bal_mc,num2cell(endBal,1),labels,colors);
%        title(ax_bal_mc,sprintf('Ending Balances at Age %d',endAge));
%
%        % Keep a useful automatic scale without cropping out low outcomes.
%        allEnd = sort(endBal(:));
%        y90 = percentile_from_sorted(allEnd,90);
%        y99 = percentile_from_sorted(allEnd,99);
%        if y99 > 0
%            ylim(ax_bal_mc,[0,max(1,1.15*y99)]);
%        else
%            ylim(ax_bal_mc,[0 1]);
%        end

        lines = {};
        lines{end+1} = sprintf('%d independent market paths for each of %d strategies; ages %d to %d',simN,K,age0,endAge);
        lines{end+1} = sprintf('Model: mu=%.2f  sigma=%.2f  inflation=%.2f  (nominal returns, return-then-withdraw)', ...
            p.mu,p.sigma,p.infl);
        lines{end+1} = repmat('-',1,106);
        lines{end+1} = sprintf('%-19s %11s %11s %13s %15s %15s', ...
            'Strategy','At $0 at end','Early $0','Med end ($)','Med total W ($)','Any shortfall');
        for k = 1:K
            dep = 100*mean(endBal(:,k)<=0);
            early = 100*mean(any(balMat{k}(:,2:end-1)<=0,2));
            totalW = sum(withMat{k},2);
            % A shortfall means scheduled spending was not fully funded.
            short = 100*mean(any(reqMat{k}>withMat{k}+1e-7,2));
            lines{end+1} = sprintf('%-19s %10.1f%% %10.1f%% %13s %15s %14.1f%%', ...
                labels{k},dep,early,prettyCash(median(endBal(:,k))), ...
                prettyCash(median(totalW)),short);
        end
        lines{end+1} = '';
        lines{end+1} = 'Probability of ending at or above each threshold:';
        hdr = sprintf('%-19s','Strategy');
        positiveThr = thr(thr>0);
        for j = 1:numel(positiveThr)
            hdr = [hdr sprintf(' %11s',prettyCash(positiveThr(j)))]; %#ok<AGROW>
        end
        lines{end+1} = hdr;
        for k = 1:K
            row = sprintf('%-19s',labels{k});
            for j = 1:numel(positiveThr)
                row = [row sprintf(' %10.1f%%',100*mean(endBal(:,k)>=positiveThr(j)))]; %#ok<AGROW>
            end
            lines{end+1} = row;
        end
        lines{end+1} = '';
        lines{end+1} = 'Early $0: balance reaches zero BEFORE the final retirement year.';
        lines{end+1} = sprintf('At end $0: includes intentional exhaustion by Drawdown at age %d (bequest = $0).',endAge);
        lines{end+1} = 'Med total W: median TOTAL nominal dollars actually withdrawn across retirement.';
        lines{end+1} = 'Bands shade the 10th-90th percentiles at each year (middle 80% of paths).';
        lines{end+1} = sprintf('GK: initial %.2f%%, guardrails +/-%.0f%%, spending changes +/-%.0f%%, cuts off final %d years', ...
            100*p.gkR0,100*p.gkBand,100*p.gkAdjust,p.gkFreeze);
        lines{end+1} = sprintf('Drawdown: assumed annual %.2f%%, end bequest target %s', ...
            100*p.drawRate,prettyCash(p.drawBequest));
        lines{end+1} = sprintf('Endowment: target %.3f%%, smoothing weight %.0f%%, payout band %.2f%%-%.2f%%', ...
            100*p.endoRate,100*p.endoWeight,100*p.endoFloor,100*p.endoCeil);
        setText(outTxt,lines);
    end

end % function CaseStudyA_V3

%% Shared simulation engine
function [bal,withdraw,gain,requested] = simulate_path(P0,returns,p,mode)
    years = numel(returns);
    bal = zeros(1,years+1); bal(1) = P0;
    withdraw = zeros(1,years);
    gain = zeros(1,years);
    requested = zeros(1,years);
    
    switch mode
        case {'fixed4','guard'}
            M = P0*p.R0;
        case 'gk'
            M = P0*p.gkR0;
        case 'endo'
            M = P0*p.endoRate;
        otherwise
            M = 0;
    end
    
    for n = 1:years
        B = bal(n); r = returns(n);
        gain(n) = B*r;
        available = max(0,B+gain(n));
    
        switch mode
            case 'fixed4'
                if n>1, M = M*(1+p.infl); end
    
            case 'guard'
                if n>1, M = M*(1+p.infl); end
                wr = M/max(B,eps);
                if wr>p.U
                    M = M*(1-p.uDown);
                elseif wr<p.L
                    M = M*(1+p.uUp);
                end
    
            case 'pct'
                M = p.alpha*B;
    
            case 'gk'
                % GK modified withdrawal rule: skip CPI adjustment after a
                % negative return if planned withdrawal rate exceeds initial.
                if n>1
                    if ~(returns(n-1)<0 && M/max(B,eps)>p.gkR0)
                        M = M*(1+p.infl);
                    end
                end
                wr = M/max(B,eps);
                remaining = years-n+1;
                if p.gkR0>0 && wr>p.gkR0*(1+p.gkBand) && remaining>p.gkFreeze
                    M = M*(1-p.gkAdjust);  % capital preservation
                elseif p.gkR0>0 && wr<p.gkR0*(1-p.gkBand)
                    M = M*(1+p.gkAdjust);  % prosperity
                end
    
            case 'draw'
                % Re-amortize beginning balance every year, with N payments
                % and terminal bequest T, at assumed annual return a.
                % Future-value equation for END-OF-YEAR withdrawals:
                %   T = B*(1+a)^N - M*((1+a)^N-1)/a.
                N = remaining_years(years,n);
                a = p.drawRate;
                T = p.drawBequest;
                if abs(a)<1e-12
                    M = max(0,(B-T)/N);
                else
                    x = (1+a)^N;
                    M = max(0, (B*x-T)*a/(x-1));
                end
                if N==1
                    % Close at actual terminal balance, if feasible; the
                    % bequest is protected only to the extent funds exist.
                    M = max(0,available-T);
                end
    
            case 'endo'
                if n>1
                    M = p.endoWeight*withdraw(n-1)*(1+p.infl) + ...
                        (1-p.endoWeight)*p.endoRate*B;
                end
                M = max(p.endoFloor*B,min(p.endoCeil*B,M));
    
            otherwise
                error('Unrecognized withdrawal mode: %s',mode);
        end
    
        requested(n) = max(0,M);
        withdraw(n) = min(requested(n),available);
        bal(n+1) = max(0,available-withdraw(n));
    end
end

function N = remaining_years(years,n)
    N = years-n+1;
end

%% UI helpers
function addHeader(parent,textLabel)
    h = uilabel(parent,'Text',['--- ' textLabel ' ---'],'FontWeight','bold');
    h.Layout.Column = [1 2];
end

function h = rateInput(parent,defaultValue,tip)
    % A user can enter either 0.04 or 4 for 4%.
    h = uieditfield(parent,'numeric','Value',defaultValue, ...
        'Limits',[0 100],'Tooltip',tip);
end

function x = asFraction(x)
    validateattributes(x,{'numeric'},{'scalar','finite','nonnegative'});
    if x>1
        x = x/100;
    end
    x = max(0,min(1,x));
end

function s = formatInteger(n)
    s = sprintf('%.0f',n);
end

function s = prettyCash(x)
    if x >= 1e9
        s = sprintf('$%.2fB',x/1e9);
    elseif x >= 1e6
        s = sprintf('$%.2fM',x/1e6);
    elseif x >= 1e3
        s = sprintf('$%.0fk',x/1e3);
    else
        s = sprintf('$%.0f',x);
    end
end

function setText(h,lines)
    if isstring(lines)
        val = cellstr(lines(:));
    elseif ischar(lines)
        val = {lines};
    elseif iscell(lines)
        val = reshape(lines,[],1);
    else
        val = {char(string(lines))};
    end
    h.Value = val;
end

%% Plotting helpers
function plotMulti(ax,x,dataCell,labels,colors,heading)
    cla(ax); hold(ax,'on');
    for k = 1:numel(dataCell)
        plot(ax,x,dataCell{k},'LineWidth',1.65,'Color',colors(k,:), ...
            'DisplayName',labels{k});
    end
    title(ax,heading);
    legend(ax,'Location','best');
end

function plotMultiBands(ax,x,dataCell,labels,colors,heading)
    cla(ax); hold(ax,'on');
    handles = gobjects(1,numel(dataCell));
    for k = 1:numel(dataCell)
        [med,lo,hi] = bands_from_matrix(dataCell{k});
        bandH = fillBand(ax,x,lo,hi,colors(k,:),.12,[labels{k} ' band']);
        bandH.HandleVisibility = 'off';
        handles(k) = plot(ax,x,med,'LineWidth',1.7,'Color',colors(k,:), ...
            'DisplayName',labels{k});
    end
    title(ax,heading);
    legend(ax,handles,labels,'Location','best');
end

function [med,lo,hi] = bands_from_matrix(M)
    [~,T] = size(M);
    med = zeros(1,T); lo = med; hi = med;
    for j = 1:T
        col = sort(M(:,j));
        med(j) = percentile_from_sorted(col,50);
        lo(j) = percentile_from_sorted(col,10);
        hi(j) = percentile_from_sorted(col,90);
    end
end

function y = percentile_from_sorted(sortedValues,p)
    n = numel(sortedValues);
    if n==0, y=NaN; return; end
    rank = p/100*(n-1)+1;
    i = floor(rank); j = ceil(rank);
    if i==j
        y = sortedValues(i);
    else
        y = sortedValues(i)+(rank-i)*(sortedValues(j)-sortedValues(i));
    end
end

function hb = fillBand(ax,x,ylo,yhi,col,opacity,label)
    X = [x,fliplr(x)];
    Y = [ylo,fliplr(yhi)];
    hb = patch('Parent',ax,'XData',X,'YData',Y, ...
        'FaceColor',col,'FaceAlpha',opacity,'EdgeColor','none', ...
        'DisplayName',label);
end

function violin_on_uiaxes(ax,dataCell,labels,colors)
    K = numel(dataCell);
    cla(ax); hold(ax,'on');
    for k = 1:K
        x = dataCell{k};
        x = sort(x(isfinite(x)));
        if isempty(x),continue;end
        lo = percentile_from_sorted(x,1);
        hi = percentile_from_sorted(x,99);
        if hi<=lo
            extra = max(1,abs(hi)*.02);
            lo = max(0,lo-extra);
            hi = hi+extra;
        end
        ygrid = linspace(lo,hi,150);
        [counts,edges] = histcounts(x,80,'BinLimits',[lo hi], ...
            'Normalization','pdf');
        centers = (edges(1:end-1)+edges(2:end))/2;
        dens = interp1(centers,counts,ygrid,'linear',0);
        kernel = exp(-(-4:4).^2/8);
        kernel = kernel/sum(kernel);
        dens = conv(dens,kernel,'same');
        if max(dens)>0
            width = .32*dens/max(dens);
        else
            width = zeros(size(dens));
        end
        patch('Parent',ax,'XData',[k-width,fliplr(k+width)], ...
            'YData',[ygrid,fliplr(ygrid)], ...
            'FaceColor',colors(k,:),'FaceAlpha',.35, ...
            'EdgeColor','none','HandleVisibility','off');
        med = percentile_from_sorted(x,50);
        q10 = percentile_from_sorted(x,10);
        q90 = percentile_from_sorted(x,90);
        plot(ax,[k-.28 k+.28],[med med],'k-','LineWidth',1.5, ...
            'HandleVisibility','off');
        plot(ax,[k k],[q10 q90],'k-','LineWidth',1.15, ...
            'HandleVisibility','off');
    end
    xlim(ax,[.5 K+.5]);
    xticks(ax,1:K);
    xticklabels(ax,labels);
    xtickangle(ax,20);
    grid(ax,'on'); box(ax,'on');
    hMed = plot(ax,NaN,NaN,'k-','LineWidth',1.5, ...
        'DisplayName','Median (horizontal)');
    hWhisker = plot(ax,NaN,NaN,'k-','LineWidth',1.15, ...
        'DisplayName','10th-90th percentile (vertical)');
    legend(ax,[hMed hWhisker],'Location','best');
end

function ylims = autoY(v)
    if isempty(v) || all(~isfinite(v)), ylims=[0 1]; return; end
    lo=min(v); hi=max(v);
    if lo==hi, lo=lo-.05; hi=hi+.05; end
    pad=.05*(hi-lo);
    ylims=[lo-pad hi+pad];
end
