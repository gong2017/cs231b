% Copyright 2011 Zdenek Kalal
% This file is part of TLD.

function tld = tldLearning(tld,I)
    bb    = tld.bb(:,I); % current bounding box
    img   = tld.img{I}; % current image

    % Check consistency -------------------------------------------------------

    pPatt  = tldGetPattern(tld, img, bb); % get current patch
    [pConf1,pIsin] = tldNN(pPatt,tld); % measure similarity to model

    if pConf1 < tld.model.nn_patch_confidence, disp('Fast change.'); tld.valid(I) = 0; return; end % too fast change of appearance
    if var(pPatt) < tld.var, disp('Low variance.'); tld.valid(I) = 0; return; end % too low variance of the patch
    if pIsin(3) == 1, disp('In negative data.'); tld.valid(I) = 0; return; end % patch is in negative data

    % Update ------------------------------------------------------------------

    overlap  = bb_overlap(bb,tld.grid); %Find overlap of bb with all boxes in tld.grid 
    [pEx, ~] = tldGeneratePositiveData(tld, overlap, img, tld.p_par_update); % generate positive example features

    [nEx, ~] = tldGenerateNegativeData(tld, I, bb, img, tld.n_par); % generate negative example features

    %%update nearest nieghbor
    tld = tldTrainNN(pEx,nEx,tld); % updating nearest neighbour 

    % ------------------------ (BEGIN) --------------------
    % TODO: update detection_model
    %
    % given:
    % ------
    %  tld.pex - positive example features (num_pos_examples X tld.model.pattern_size)
    %  tld.nex - negative example features (num_neg_examples X tld.model.pattern_size)
    %  bb -- current bounding box of object in image

    % to update or compute :
    % --------------------
    %  tld.detection_model -- update the detection with the new tld.pex, tld.nex feature vectors 

    X = cat(2, tld.pEx{1}, tld.nEx{1})';
    y = [ones(1, size(tld.pEx{1}, 2)) zeros(1, size(tld.nEx{1}, 2))]';

    tld.detection_model = trainLearner(tld, X, y);

    % ------------------------ (END) --------------------------

end

