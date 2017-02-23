function dataM=ns_applyprojmat(par,data)
% function dataM = ns_pca(par,data)
% applies ECG-EOG PCA components to ft dataset
M = ns_projmat(par);

dataM=data;
for i=1:length(data.trial)
    dataM.trial{i}=M*data.trial{i};
end; 