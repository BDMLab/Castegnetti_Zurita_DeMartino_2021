%% behaviour
% ~~~
% This script contains the analyses made for the behavioural results of the
% paper "How usefulness shapes neural representations during goal-directed
% behaviour" (2021) by Giuseppe Castegnetti, Mariana Zurita and Benedetto 
% De Martino.
% ~~~
% Written by GX Castegnetti and M Zurita

clear all
close all
clc

%% Folders
fs      = filesep;
dirHere = pwd;
idcs    = strfind(dirHere,fs);
dirNew  = dirHere(1:idcs(end-1)-1); 
dir.beh = [dirNew,fs,'data',fs,'behaviour'];
dir.psy = [dirNew,fs,'data',fs,'fmri',fs,'psychOut'];

%% Select subjects and trials

% Final set of included subjects
subs = [4:5 7 8 9 13:17 19 21 23 25:26 29:32 34:35 37 39:43 47:49]; 
taskOrd = [ones(1,10),2*ones(1,10),1,2,ones(1,5),2*ones(1,3)];

% % Include subjects 10, 27, 36, 44 and 50 that were excluded because of behaviour 
% subs = [4:5 7 8 9 10 13:17 19 21 23 25:26 27 29:32 34:36 37 39:43 44 47:49 50];
% taskOrd = [ones(1,11),2*ones(1,11),1,1,2,ones(1,5),2*ones(1,4) 1];

% Note: subjects begin with number 4 because the ones before were pilots.

ntrials = 120;

%% Plots settings
plot_rda_SS = false;
plot_his_SS = 1;
plot_den_SS = false;
hist_fire_color = [0.8706 0.4196 0.1569];
hist_boat_color = [0.2627 0.5255 0.5882];

%% Read tables
objVersion  = 3; % set which column to read according to the object set (actually used vs. training)
objs        = readtable([dir.beh,fs,'Objects.csv']);
foo         = logical(table2array(objs(:,objVersion)));
objsName    = table2cell(objs(foo,2)); clear foo objs

%% Allocate memory
rsmStack_F = nan(length(subs),ntrials,ntrials);
rsmStack_B = nan(length(subs),ntrials,ntrials);
val_F      = nan(length(subs),ntrials);
val_B      = nan(length(subs),ntrials);
con_F      = nan(length(subs),ntrials);
con_B      = nan(length(subs),ntrials);
pri        = nan(length(subs),ntrials);
allSubs    = [];
allCond    = [];
alldV      = [];
allSumV    = [];
alldC_opp  = [];
alldV_opp  = [];
allSumV_opp = [];
allSumC_opp = [];
alldC      = [];
allSumC    = [];
allCho     = [];
allRT      = [];
allPrice   = [];

%% Initialise figures
plotCho = figure('color',[1 1 1]);

%% Loop over subjects to read and organise data and then plot choice 
% depending on the difference in value (logistic regression)
for s = 1:length(subs)
    
    %% day 1 - extract data
    
    % extract data matrices
    data_F = csvread([dirNew,fs,'data',fs,'behaviour',fs,'SF',num2str(subs(s),'%03d'),fs,'SF',num2str(subs(s),'%03d'),'_B1_DRE.csv']); % value/conf. fire
    data_B = csvread([dirNew,fs,'data',fs,'behaviour',fs,'SF',num2str(subs(s),'%03d'),fs,'SF',num2str(subs(s),'%03d'),'_B2_DRE.csv']); % value/conf. boat
    data_p = csvread([dirNew,fs,'data',fs,'behaviour',fs,'SF',num2str(subs(s),'%03d'),'/SF',num2str(subs(s),'%03d'),'_PE_DRE.csv']); % familiarity/price
    
    % sort according to object
    [~, idx_F] = sort(data_F(:,2));
    [~, idx_B] = sort(data_B(:,2));
    [~, idx_p] = sort(data_p(:,2));
    
    % extract rating
    val_F(s,:) = data_F(idx_F,3);
    val_B(s,:) = data_B(idx_B,3);
    
    % extract confidence
    con_F(s,:) = data_F(idx_F,4);
    con_B(s,:) = data_B(idx_B,4);
    
    % extract price
    pri(s,:) = data_p(idx_p,4);
    
    % create matrix useful later for computing correlations
    all_scores{s} = [val_F(s,:)' val_B(s,:)' con_F(s,:)' con_B(s,:)' pri(s,:)'];
    allValsBothGoals(:,s) = [val_F(s,:)';val_B(s,:)'];
    
    
    %% day 2 - extract choices
    
    % extract data from the four sessions (1: #trial; 2: TrialStart; 3: TrialType; 4-5: Pic(s)ID; 6: TrialEnd; 7: KeyID; 8: Latency)
    if taskOrd(s) == 1
        goal1 = 'F';
        goal2 = 'B';
    else
        goal1 = 'B';
        goal2 = 'F';
    end
    
    % extract psychopy data from the four scanning sessions
    data_mri_1 = csvread([dir.psy,fs,'SF',num2str(subs(s),'%03d'),fs,'DRE_mri_S',num2str(subs(s),'%03d'),'_B1',goal1,'.csv']);
    data_mri_2 = csvread([dir.psy,fs,'SF',num2str(subs(s),'%03d'),fs,'DRE_mri_S',num2str(subs(s),'%03d'),'_B2',goal2,'.csv']);
    data_mri_3 = csvread([dir.psy,fs,'SF',num2str(subs(s),'%03d'),fs,'DRE_mri_S',num2str(subs(s),'%03d'),'_B3',goal1,'.csv']);
    data_mri_4 = csvread([dir.psy,fs,'SF',num2str(subs(s),'%03d'),fs,'DRE_mri_S',num2str(subs(s),'%03d'),'_B4',goal2,'.csv']);
    
    % concatenate sessions
    if taskOrd(s) == 1
        data_mri_F = [data_mri_1; data_mri_3];
        data_mri_B = [data_mri_2; data_mri_4];
    else
        data_mri_F = [data_mri_2; data_mri_4];
        data_mri_B = [data_mri_1; data_mri_3];
    end
    
    % extract indices of choice trials
    idxCho_F = data_mri_F(:,3) == 1;
    idxCho_B = data_mri_B(:,3) == 1;
    
    % vector with 3 columns: L obj, R obj, choice
    choice_F = [data_mri_F(idxCho_F,4:5) data_mri_F(idxCho_F,7:8)];
    choice_B = [data_mri_B(idxCho_B,4:5) data_mri_B(idxCho_B,7:8)];
    
    clear data_mri_1 data_mri_2 data_mri_3 data_mri_4 idxCho_F idxCho_B goal 1 goal2
    
    %% val, con, vs RT
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % find value and  confindece of the objects %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    for i = 1:length(choice_F)
        
        % --- find when they were presented on day 1 ---
        
        % fire
        idxCho_F_L(i) = find(data_F(:,2) == choice_F(i,1));
        idxCho_F_R(i) = find(data_F(:,2) == choice_F(i,2));
        
        % boat
        idxCho_B_L(i) = find(data_B(:,2) == choice_B(i,1));
        idxCho_B_R(i) = find(data_B(:,2) == choice_B(i,2));
        
        % --- find val, con assigned on day 1 ---
        
        % fire
        if choice_F(i,3) == -1
            valCho_F(i) = data_F(idxCho_F_L(i),3);
            valUnc_F(i) = data_F(idxCho_F_R(i),3);
            conCho_F(i) = data_F(idxCho_F_L(i),4);
            conUnc_F(i) = data_F(idxCho_F_R(i),4);
        elseif choice_F(i,3) == 1
            valCho_F(i) = data_F(idxCho_F_R(i),3);
            valUnc_F(i) = data_F(idxCho_F_L(i),3);
            conCho_F(i) = data_F(idxCho_F_R(i),4);
            conUnc_F(i) = data_F(idxCho_F_L(i),4);
        end
        
        % boat
        if choice_B(i,3) == -1
            valCho_B(i) = data_B(idxCho_B_L(i),3);
            valUnc_B(i) = data_B(idxCho_B_R(i),3);
            conCho_B(i) = data_B(idxCho_B_L(i),4);
            conUnc_B(i) = data_B(idxCho_B_R(i),4);
        elseif choice_B(i,3) == 1
            valCho_B(i) = data_B(idxCho_B_R(i),3);
            valUnc_B(i) = data_B(idxCho_B_L(i),3);
            conCho_B(i) = data_B(idxCho_B_R(i),4);
            conUnc_B(i) = data_B(idxCho_B_L(i),4);
        end
        
    end
    
    % put conditions together
    valCho = [valCho_F'; valCho_B'];
    valUnc = [valUnc_F'; valUnc_B'];
    conCho = [conCho_F'; conCho_B'];
    conUnc = [conUnc_F'; conUnc_B'];
    
    % take absolute difference
    valDif = abs(valCho - valUnc);
    conDif = abs(conCho - conUnc);
    
    % take chosen - unchosen
    valChMUnc = valCho - valUnc;
    conChMUnc = conCho - conUnc;
    
    %%%%%%%%%%%%%%%%%
    % answers (L/R) %
    %%%%%%%%%%%%%%%%%
    
    choices_L(s) = numel(find(choice_F(:,3) == -1)) + numel(find(choice_B(:,3) == -1));
    choices_R(s) = numel(find(choice_F(:,3) == +1)) + numel(find(choice_B(:,3) == +1));
    
    %%%%%%%%%%%%
    % take RTs %
    %%%%%%%%%%%%
    
    rt_F = choice_F(:,4);
    rt_B = choice_B(:,4);
    rt = [rt_F;rt_B];
    
    % take means
    rt_F_mean(s) = nanmean(rt_F);
    rt_B_mean(s) = nanmean(rt_B);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % correlations scores/RTs %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    r_valDif = corr(rt,valDif,'rows','complete');
    r_conDif = corr(rt,conDif,'rows','complete');
    r_valChMUnc = corr(rt,valChMUnc,'rows','complete');
    r_conChMUnc = corr(rt,conChMUnc,'rows','complete');
    
    fooPlot_ChMUnc(s,:) = [r_valChMUnc r_conChMUnc];
    fooPlot_Chosen(s,:) = [r_valChMUnc r_conChMUnc];
    
    
    %% logistic regression of choice on day 2 from rating on day 1
    
    % loop over (48) choice trials for each goal
    for i = 1:length(choice_F)
        
        %%%%%%%%
        % fire %
        %%%%%%%%
        
        % extract ID of the two objects being displayed
        item_id_F_L = choice_F(i,1);
        item_id_F_R = choice_F(i,2);
        
        % dV
        item_rating_F_L = data_F(data_F(:,2) == item_id_F_L,3);
        item_rating_F_R = data_F(data_F(:,2) == item_id_F_R,3);
        dV_F(i) = item_rating_F_R - item_rating_F_L; %#ok<*SAGROW>
        sumV_F(i) = item_rating_F_R + item_rating_F_L;
        
        % dC
        item_confid_F_L = data_F(data_F(:,2) == item_id_F_L,4);
        item_confid_F_R = data_F(data_F(:,2) == item_id_F_R,4);
        dC_F(i) = item_confid_F_R - item_confid_F_L;
        sumC_F(i) = item_confid_F_R + item_confid_F_L;
        
        % dPrice
        item_price_F_L = data_p(data_p(:,2) == item_id_F_L,4);
        item_price_F_R = data_p(data_p(:,2) == item_id_F_R,4);
        dP_F(i) = item_price_F_R - item_price_F_L;
        
        %%%%%%%%
        % boat %
        %%%%%%%%
        
        % extract ID of the two objects being displayed
        item_id_B_L = choice_B(i,1);
        item_id_B_R = choice_B(i,2);
        
        % dV
        item_rating_B_L = data_B(data_B(:,2) == item_id_B_L,3);
        item_rating_B_R = data_B(data_B(:,2) == item_id_B_R,3);
        dV_B(i) = item_rating_B_R - item_rating_B_L;
        sumV_B(i) = item_rating_B_R + item_rating_B_L;
        
        % dC
        item_confid_B_L = data_B(data_B(:,2) == item_id_B_L,4);
        item_confid_B_R = data_B(data_B(:,2) == item_id_B_R,4);
        dC_B(i) = item_confid_B_R - item_confid_B_L;
        sumC_B(i) = item_confid_B_R + item_confid_B_L;
        
        % dPrice
        item_price_B_L = data_p(data_p(:,2) == item_id_B_L,4);
        item_price_B_R = data_p(data_p(:,2) == item_id_B_R,4);
        dP_B(i) = item_price_B_R - item_price_B_L;
        
    end, clear item_id_F_L item_id_F_R item_id_B_L item_id_B_R item_rating_F_L item_rating_F_R item_rating_B_L item_rating_B_R
    
    % column vectors are nicer
    dV_F = dV_F(:);
    dV_B = dV_B(:);
    dC_F = dC_F(:);
    dC_B = dC_B(:);
    dP_F = dP_F(:);
    dP_B = dP_B(:);    
    sumV_F = sumV_F(:);
    sumV_B = sumV_B(:);
    sumC_F = sumC_F(:);
    sumC_B = sumC_B(:);
    
    % logistic regressions
    mdl_FonF = fitglm(dV_F,(choice_F(:,3)+1)/2,'interactions','Distribution','binomial'); % choice during F vs rating during F
    mdl_BonB = fitglm(dV_B,(choice_B(:,3)+1)/2,'interactions','Distribution','binomial'); % choice during B vs rating during B
    mdl_BonF = fitglm(dV_F,(choice_B(:,3)+1)/2,'interactions','Distribution','binomial'); % choice during B vs rating during F
    mdl_FonB = fitglm(dV_B,(choice_F(:,3)+1)/2,'interactions','Distribution','binomial'); % choice during F vs rating during B
    
    % extract p values (just better interpretation at this stage)
    pVal(s).('FonF') = mdl_FonF.Coefficients.pValue(2);
    pVal(s).('FonB') = mdl_FonB.Coefficients.pValue(2);
    pVal(s).('BonB') = mdl_BonB.Coefficients.pValue(2);
    pVal(s).('BonF') = mdl_BonF.Coefficients.pValue(2);
    
    % extract slopes
    slopes(s).('FonF') = mdl_FonF.Coefficients.Estimate(2);
    slopes(s).('FonB') = mdl_FonB.Coefficients.Estimate(2);
    slopes(s).('BonB') = mdl_BonB.Coefficients.Estimate(2);
    slopes(s).('BonF') = mdl_BonF.Coefficients.Estimate(2);
    
    % extract offsets
    offset(s).('FonF') = mdl_FonF.Coefficients.Estimate(1);
    offset(s).('FonB') = mdl_FonB.Coefficients.Estimate(1);
    offset(s).('BonB') = mdl_BonB.Coefficients.Estimate(1);
    offset(s).('BonF') = mdl_BonF.Coefficients.Estimate(1);
    
    %% create vectors for table
    allSubs     = [allSubs; s*ones(2*length(choice_F),1)];
    allCond     = [allCond; ones(length(choice_F),1); 2*ones(length(choice_F),1)];
    alldV       = [alldV; dV_F/50; dV_B/50];
    alldC       = [alldC; dC_F/50; dC_B/50];
    allSumV     = [allSumV; sumV_F/50; sumV_B/50];
    allSumV_opp = [allSumV_opp; sumV_B/50; sumV_F/50];
    allPrice    = [allPrice; dP_F; dP_B];  
    allSumC     = [allSumC;     sumC_F/50; sumC_B/50];
    allSumC_opp = [allSumC_opp; sumC_B/50; sumC_F/50];
    alldV_opp   = [alldV_opp; dV_B/50; dV_F/50];
    alldC_opp   = [alldC_opp; dC_B/50; dC_F/50];
    allCho  = [allCho; choice_F(:,3); choice_B(:,3)];
    allRT  = [allRT; choice_F(:,4); choice_B(:,4)];
    
    %% plot logistic curves of choice vs dV
    
    % draw sigmoids with the fitted parameters
    xspan = -49:0.1:49;
    sigm_FonF = sigmf(xspan,[mdl_FonF.Coefficients.Estimate(2) mdl_FonF.Coefficients.Estimate(1)]);
    sigm_BonB = sigmf(xspan,[mdl_BonB.Coefficients.Estimate(2) mdl_BonB.Coefficients.Estimate(1)]);
    sigm_BonF = sigmf(xspan,[mdl_BonF.Coefficients.Estimate(2) mdl_BonF.Coefficients.Estimate(1)]);
    sigm_FonB = sigmf(xspan,[mdl_FonB.Coefficients.Estimate(2) mdl_FonB.Coefficients.Estimate(1)]);
    clear mdl_FonF mdl_BonB mdl_FonB mdl_BonF
    
    % choice during fire
    plotTight = 7;
    figure(plotCho)
    subplot(7,plotTight*5,1+plotTight*(s-1):3+plotTight*(s-1))
    plot(xspan,sigm_FonF,'linewidth',5,'color',hist_fire_color), hold on % based on value assigned during fire
    plot(xspan,sigm_FonB,'linewidth',5,'color',hist_boat_color) % based on value assigned during boat
    plot(dV_F,(choice_F(:,3)+1)/2,'linestyle','none','marker','.','markersize',20,'color','k')
    set(gca,'fontsize',12,'ytick',[],'xtick',[-40 0 40],...
        'xcolor',hist_fire_color,'ycolor',hist_fire_color,...
        'LineWidth',2)
    ylim([-0.1 1.1])
    title(['S#',num2str(s),': BURN.'],'fontsize',14)
    %     legend('F-based','B-based')
    
    % make label closer to axis
    xh = get(gca,'xlabel'); % handle to the label object
    p = get(xh,'position'); % get the current position property
    p(2) = 0.25*p(2) ;      % reduce distance,
    set(xh,'position',p)    % set the new position
    
    % choice during boat
    subplot(7,plotTight*5,4+plotTight*(s-1):6+plotTight*(s-1))
    plot(xspan,sigm_BonB,'linewidth',5,'color',hist_boat_color),hold on % based on value assigned during boat
    plot(xspan,sigm_BonF,'linewidth',5,'color',hist_fire_color) % based on value assigned during fire
    plot(dV_B,(choice_B(:,3)+1)/2,'linestyle','none','marker','.','markersize',20,'color','k')
    set(gca,'fontsize',12,'ytick',[],'xtick',[-40 0 40],...
        'xcolor',hist_boat_color,'ycolor',hist_boat_color,...
        'LineWidth',2)
    ylim([-0.1 1.1])
    title(['S#',num2str(s),': ANCH.'],'fontsize',14)
    
    % make label closer to axis
    xh = get(gca,'xlabel'); % handle to the label object
    p = get(xh,'position'); % get the current position property
    p(2) = 0.25*p(2) ;      % reduce distance,
    set(xh,'position',p)    % set the new position
    
end

%% Correlation between behavioural measures - Table 1

for s = 1:length(subs)
    % compute correlation between val_F, val_B, con_F, con_B, and pri for each subject
    cMat(:,:,s) = corr(all_scores{s},'rows','complete');
end, clear s

% Data for Table 1
corr_matrix_mean = squeeze(mean(cMat,3));
corr_matrix_std  = squeeze(std(cMat,0,3));
corr_matrix_min  = squeeze(min(cMat,[],3));
corr_matrix_max  = squeeze(max(cMat,[],3));

%% Relationship between confidence and value

% Gather all data together
all_confidence = [con_B(:); con_F(:)];
all_value = [val_B(:); val_F(:)];

% Eliminate pairs with nans in confidence
nan_idxs = isnan(all_confidence);
all_confidence(nan_idxs) = [];
all_value(nan_idxs) = [];

% Eliminate pairs with nans in value
nan_idxs = isnan(all_value);
all_confidence(nan_idxs) = [];
all_value(nan_idxs) = [];

% Run the following line without the ';' to get the regression estimate 
% and stats, showing the quadratic relationship between value and
% confidence.
mdl_val_conf = fitglm(all_value,all_confidence,'quadratic')

%% Reaction time

% RT grand mean
rt_mean = mean([rt_F_mean rt_B_mean]);
% RT stats
[~,p_RT,~,stats_RT] = ttest(rt_F_mean,rt_B_mean);

%% Group level logistic regression for choice

% create table
tblChoice = table(allSubs,allCond,alldV,alldV_opp,allSumV,allSumV_opp,alldC,alldC_opp,allSumC,allSumC_opp,allPrice,(allCho+1)/2,allRT);
tblChoice.Properties.VariableNames = {'sub','cond','dV','dVo','sumV','sumVo','dC','dCo','sumC','sumCo','price','choice','RT'};

% fit lme
lmeChoice = fitglme(tblChoice,'choice ~ 1 + cond + dV + dVo + dC + dCo + dV:dC + dVo:dCo + price + (cond + dV + dVo + dC + dCo + dV:dC + dVo:dCo + price | sub)','distribution','binomial')



