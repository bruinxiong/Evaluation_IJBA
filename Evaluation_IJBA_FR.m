%% IJBA Evaluation codes on all 10 splits for face identification task with Template Adaptation(mean coding for video frames) 
% You can reproduce our single model (ResNext 152 trained on our own face dataset illustrated by our arXiv paper 
% :"A Good Practice Towards Top Performance of Face Recognition: Transferred Deep Feature Fusion") results based on score matrix given by
% corresponding folders. Due to the limitation of company, we can not
% provide ResNext 152 and SE-ResNext 101 models. Moreover, all the features
% of IJBA data and Template Adaptation models will relase later (too many files need to be uploaded, so they will not come recently)
% Coded by Lin Xiong and Jian Zhao May-5, 2018

clc
clear all;
model_path_dir = '../models/_template_resnext/';
for sp = 1:10
    clear S_PQ;
	addpath(strcat(model_path_dir,'split',int2str(sp),'//'))

    mkdir(strcat(model_path_dir,'split',int2str(sp),'//Results_RSX152'))
    saveTxtPath = strcat(model_path_dir,'.//split',int2str(sp),'//Results_RSX152','//result');

    GALLERY_TEMPLATE_ID = load(strcat(model_path_dir,'.//split',int2str(sp),'//gallery_TEMPLATE_ID.txt'));
    GALLERY_MEDIA_ID = load(strcat(model_path_dir,'.//split',int2str(sp),'//gallery_MEDIA_ID.txt'));
    PROBE_TEMPLATE_ID = load(strcat(model_path_dir,'.//split',int2str(sp),'//probe_TEMPLATE_ID.txt'));
    PROBE_MEDIA_ID = load(strcat(model_path_dir,'.//split',int2str(sp),'//probe_MEDIA_ID.txt'));
    unique_template_id_gallery = unique(GALLERY_TEMPLATE_ID);
    unique_media_id_gallery = unique(GALLERY_MEDIA_ID);
    unique_template_id_probe = unique(PROBE_TEMPLATE_ID);
    unique_media_id_probe = unique(PROBE_MEDIA_ID);

    load(strcat(model_path_dir,'.//split',int2str(sp),'//template_subject_probe'))
	load(strcat(model_path_dir,'.//split',int2str(sp),'//template_subject_gallery'))
	load(strcat(model_path_dir,'.//split',int2str(sp),'//template_media_probe'))
	load(strcat(model_path_dir,'.//split',int2str(sp),'//template_media_gallery'))

	beta = 0;
    load(strcat(model_path_dir,'split',int2str(sp),'/ScoreMatrix_RSX152/','S_PQ_','Beta_',num2str(beta),'_','split',int2str(sp),'.mat'));

	%% Open set
	% Find the subjects unenrolled
	enroll_indicator = zeros(length(template_subject_probe),1);
	right_size = 0;
    for u = 1:length(template_subject_probe)
        if(length(find(template_subject_gallery==template_subject_probe(u))))
            enroll_indicator(u) = 1;
            right_size = right_size+1;  
        end
    end
	unenroll = find(enroll_indicator==0);
	enroll = find(enroll_indicator==1);

	% Calculate maximum score for wrong pairs
	score_max = zeros(length(unenroll),1); 
	for i=1:length(unenroll)
	    ue_index = unenroll(i);
	   [dist_val dist_ind] = max(S_PQ(:,ue_index));
	   score_max(i) = dist_val;
	end

	% Obtain threshold
	min_value = min(score_max);
	max_value = max(score_max);
	inteval = abs(max_value-min_value)/1000;
	for i=1:1000
	    stop(i) = min_value + inteval*i;
	    x(i) = length(find(score_max>=stop(i)))/length(score_max);
	    is_correct = 0;
	    for e=1:length(enroll)
		e_index = enroll(e);
	       [dist_val dist_ind] = max(S_PQ(:,e_index));
	       if template_subject_gallery(dist_ind) == template_subject_probe(e_index) && dist_val >= stop(i)
		    is_correct = is_correct + 1;
	       end
        end
	    y(i) = is_correct / length(enroll);

	end

	I001  = find(abs(x-0.01) <= 0.002);
	I01   = find(abs(x-0.1) <= 0.01);
	Y001 = y(I001(1))
	Y01  = y(I01(1))
	figure;
	xlabel ('FPIR');
	ylabel ('TPIR');
	hold on;
	plot(x,y, 'b', 'LineWidth',2);
	hold off;
    fw = fopen(strcat(saveTxtPath,'_','Beta_',num2str(beta),'_TA_open.txt'),'a');
    fprintf(fw,'\n%f\t%f\n', Y001, Y01);
    fclose(fw);

	%% Close set
	acc = [];
	for r = 1:100
	    correct = 0;
        for p = 1:length(unique_template_id_probe)		
            [Y,I] = sort(S_PQ(:,p));
            if (find(template_subject_gallery(I(end-(r-1):end)) == template_subject_probe(p)))
                correct = correct +1;
            end  
        end
	    acc(r) = correct / (length(unique_template_id_probe)-length(unenroll));
	end

	Rank = [1:1:100];
	figure;
	title('CMC');
	xlabel ('Rank');
	ylabel ('Matching Rate');
	hold on;
	plot(Rank, acc, 'g-o', 'LineWidth',2);
	hold off;

    legendEntries{1} = sprintf('%s %s (%.2f %%) %s (%.2f %%) %s (%.2f %%)', upper('Resnext 152 +TA'), '@Rank 1', 100*acc(1), '@Rank 5', 100*acc(5), '@Rank 10', 100*acc(10));

	legend(legendEntries, 'FontSize', 11, 'FontWeight', 'normal', 'Location', 'SouthEast');
    fw = fopen(strcat(saveTxtPath,'_','Beta_',num2str(beta),'_TA_close.txt'),'a');
    % Close rank1, rank5, rank10
    fprintf(fw,'\n%f\t%f\t%f\n',acc(1), acc(5), acc(10));
    fclose(fw);
end

