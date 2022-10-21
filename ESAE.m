%%%%%%%%%%%%%%%%%%%%%%%%  Embedded stacked sparse autoencoder  %%%%%%%%%%%%%%%%%%%
%%https://blog.csdn.net/qq_36108664/article/details/107809983
clear ; close all; clc
rng('default')%�����������,�����ʼȨֵ�������ʼ���ģ�����ÿ�ε�ʵ������һ��
tic;
load ("L0/vehicle/vehicle4.mat"); 
% [trainX1,trainY1] = k_means(trainX,trainY,type_num,0.5); % �ھ��������ռ���ѵ��������
% trainX = sample_pair_trainX;
% trainY = sample_pair_trainY;
% testX = sample_pair_testX;
% testY = sample_pair_testY;
% trainX = trainX1;
% trainY = trainY1;
% testX = testX2;
% testY = testY2;
T = constructT(trainY);               %��ǩ�����one-hot��ʽ��softmax���õ�
trainX_map  = mapminmax(trainX',0,1); %������һ��,�������ļ������sigmoid�����Χ��0-1
testX_map = mapminmax(testX',0,1);
record = [];
[m,n]= size(trainX);
[m1,n1]= size(testX);
best_accuracy = 1;

L2WeightRegularization = 0.001; %������ͷ�ϵ��
SparsityRegularization =5;     %ϵ����ͷ�ϵ��
SparsityProportion = 0.05;      %ϡ����� ����������������Ҫ����,�������Ա����������в���������ʱ���ã�
%%
% for L2WeightRegularization=[0.0001,0.001,0.01]
%     for SparsityRegularization=[1,2,3,4,5,6]
%         for SparsityProportion = [0.02,0.04,0.06,0.08,0.1]
% L2WeightRegularization = 0.0001; %������ͷ�ϵ��

%%%%i,j,k ����������Ԫ����û�мȶ�������׼�򣬸�����������������������ȷ����ΧѰ��%%%
for i = 240													
    for j = 120
        for k = 2:2:18 													
            hiddenSize = i;
            autoenc1 = trainAutoencoder(trainX',hiddenSize,...%�������������ݸ�ʽ: d*N,�ú���Ĭ�϶��������ݹ�һ������
                'MaxEpochs',1000,...  %��������
                'L2WeightRegularization',L2WeightRegularization,...%��ʧ������L2Ȩ�ص�������ϵ����=0.0001
                'SparsityRegularization',SparsityRegularization,...%����ϡ���������Գɱ�������Ӱ���ϵ����=4
                'SparsityProportion',SparsityProportion,...%���������ز������ϡ����
                'encoderTransferFunction','logsig',...%�����������
                'DecoderTransferFunction','logsig');  %�����������
            %Extract the features in the hidden layer.
            features1 = encode(autoenc1,trainX');%ʹ���Ա��������������ݽ��б���
            %Ƕ��ԭʼ��������һ�����������������
            features1 = [features1;trainX_map];
            features1 = featureChoose(features1, i); 

            hiddenSize = j;
            autoenc2 = trainAutoencoder(features1,hiddenSize,...
                 'MaxEpochs',1000,...
                'L2WeightRegularization',L2WeightRegularization,...
                'SparsityRegularization',SparsityRegularization,...
                'SparsityProportion',SparsityProportion,...
                'encoderTransferFunction','logsig',...
                'DecoderTransferFunction','logsig');
            %Extract the features in the hidden layer.
%ʹ�õ�һ���Ա������������Ϊ�ڶ����Ա����������롣
            features2 = encode(autoenc2,features1);
            features2 = [features2;trainX_map];
            features2 = featureChoose(features2, j); 

            hiddenSize = k;
            autoenc3 = trainAutoencoder(features2,hiddenSize,...
                 'MaxEpochs',1000,...
                'L2WeightRegularization',L2WeightRegularization,...
                'SparsityRegularization',SparsityRegularization,...
                'SparsityProportion',SparsityProportion,...
                'encoderTransferFunction','logsig',...
                'DecoderTransferFunction','logsig');
            %Extract the features in the hidden layer.
            features3 = encode(autoenc3,features2);
           %%%%������Ԥѵ���׶�%%%%%
            
            
            %����softmax����㣬ʹ��ѵ�����ݵı�ǩ���мල��ʽѵ�� softmax �㡣
            softnet = trainSoftmaxLayer(features3,T,'LossFunction','crossentropy'); 
            %trainSoftmaxLayer(���������������ǩ������(ѭ������)������ֵ)

           
            
            deepnet = stack(autoenc1,autoenc2,autoenc3,softnet);%�����ջ���������Ա������еı�������������ȡ�����������Խ��Ա������еı������� softmax ��ѵ���һ�����γ����ڷ���Ķѵ�����
            
            deepnet = train(deepnet,trainX',T);%����΢����ͨ�����мල��ʽ����ѵ����������ѵ��������΢������
            
            %��ѵ���õ������ѵ�����Ͳ��Լ����б���
            train_deepFeature = coding(deepnet,m, trainX_map');%ѵ���������������ȡ
            test_deepFeature = coding(deepnet,m1, testX_map');%��������������ȡ

            model = svmtrain(trainY,train_deepFeature,'-s 0 -c 10^5 -t 0 -q'); %ѵ��������
            svm_pred = svmpredict(testY,test_deepFeature,model); 
            accuracy = mean(double(svm_pred == testY)) * 100; 
            if(accuracy > best_accuracy)
                trainX_deep_best = train_deepFeature;
                testX_deep_best = test_deepFeature;
                best_accuracy = accuracy;
                network = deepnet;
                BestL2=L2WeightRegularization;
                BestSR=SparsityRegularization;
                BestSP=SparsityProportion;
%                 besti=i
%                 bestj=j
%                 bestk=k
                        end
    end
end
            end
%         end
%     end 
% end
toc;
% %%��¼��������ֵ
% besti
% bestj
% % bestk
%   BestL2
%    BestSR
%    BestSP

%  view(deepnet)
 view(network)
% network1 = network;
% trainX_deep_cluster1 = trainX_deep_best;%һ�ξ��������ռ�����ȡ����������
% testX_deep_cluster1 = testX_deep_best;
% network2 = network;
% trainX_deep_cluster2 = trainX_deep_best;%���ξ��������ռ�����ȡ����������
% testX_deep_cluster2 = testX_deep_best;
% save("C1/AD/AD1_newDF","trainX_deep_cluster1","testX_deep_cluster1","network");%����������ɵ�����
trainX_deep_cluster0 = trainX_deep_best;
testX_deep_cluster0 = testX_deep_best;
save("L0/vehicle/vehicle4_newDF","trainX_deep_cluster0","testX_deep_cluster0","network","-append"); %�����������
 

 
