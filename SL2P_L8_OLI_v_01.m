function SL2P(varargin)

%% 1. Initialization
if ~ismember(nargin,[2,3]), disp({'!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!ERROR!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';'--usage : Matlab SL2P [input_path\] [S2 tiff data folder] [output_path\ (optional)]'});return; end;

addpath(genpath('.\tools'));
addpath(genpath('.\aux_data'));

bio_vars={'LAI','FCOVER','FAPAR','LAI_Cab','LAI_Cw'};
BIO_VAR_bounding_box=importdata('G:\Najib\6_SL2P_regularizing\SL2P_V1-master\tools\aux_data\BIO_VAR_bounding_box.mat');

file_name=dir([varargin{1},varargin{2},'\*.xml']);
file_name=file_name(1).name(1:end-4);

if nargin==3,   out_path=[varargin{3},varargin{2},'_SL2P_bio\'];
    else,out_path=[varargin{1},strrep(varargin{2},'L2A','L2B'),'\'];
end;
if ~isfolder(out_path), mkdir (out_path); end;   
%% 2.1 Loading data........................................................
disp({'===============',file_name,'==============='});%L8: green, red, nir, swir1, swir2, }, cos(VZA), cos(SZA), cos(RAA)
disp({'--Loading data--------------------------------------'});
Input_NNT=[]; 
h = waitbar(0,'Loading data...');

for bb={'sr_band3','sr_band4','sr_band5','sr_band6','sr_band7','solar_zenith','sensor_zenith','solar_azimuth','sensor_azimuth'}
    waitbar(size(Input_NNT,2)/11)
    file_name_band=dir([varargin{1},varargin{2},'\*',char(bb),'*.tif']);
    [band,xb,yb,Ib] = geoimread([varargin{1},varargin{2},'\',file_name_band(1).name]);
    [r,c]=size(band);
    Input_NNT= [Input_NNT,double(reshape(band,r*c,1))]; 
end;
%% 2.2 Adding image cordinates
Input_NNT=[reshape((1:r)'*ones(1,c),r*c,1),reshape(ones(1,r)'*(1:c),r*c,1),Input_NNT];
%% 2.3 Organizing input data for NNET (NNET_IN)
Input_NNT(:,end-1)=abs(Input_NNT(:,end-1)-Input_NNT(:,end));Input_NNT(:,end)=[];
Input_NNT(:,3:end-3)=Input_NNT(:,3:end-3)/10000;
Input_NNT(:,end-2:end)=Input_NNT(:,end-2:end)/100;
Input_NNT(:,end-2:end)=cos(deg2rad(Input_NNT(:,end-2:end))); 
NNT_IN=Input_NNT(:,3:end)';

close(h)
%% 3. Loading NET
disp({'--Loading NNET--------------------------------------'});
NET_estim=importdata('.\tools\aux_data\L8_OLI_NNET.mat');
NET_uncer=importdata('.\tools\aux_data\L8_OLI_SL2P_NNT_unc.mat');
%% 2.4 Computing input_flags 
input_out_of_range=input_out_of_range_flag_function_SL2P(Input_NNT(:,3:end-3),r,c);
%% 5. Simulating biophysical parameters (SL2P).....................................
disp({'--Simulating vegetation biophysical variables ------'});
NNT_OUT=[];
h = waitbar(0,'Simulating bio- variables...');
for ivar=1:length(bio_vars),
    waitbar(ivar/length(bio_vars))
    bio=bio_vars{ivar};
    bio_sim= [Input_NNT(:,1:2),NaN+Input_NNT(:,1)];

    eval(['NET_ivar= NET_estim.',bio,'.NET;']);
    eval(['NET_unc       = NET_uncer.',bio,'.NET;']);
    
    bio_sim (:,3)= sim(NET_ivar, NNT_IN)';
    bio_sim (:,4)= sim(NET_unc, [NNT_IN(6:end,:);NNT_IN(1:5,:)])';    
    %% Creating output_thresholded_to_min/max_outpout flag
    eval(['bounding_box=BIO_VAR_bounding_box.',bio,';']);
    output_thresholded_to_min_outpout=0*bio_sim(:,3);
    output_thresholded_to_min_outpout(find(bio_sim(:,3)<bounding_box.Pmin & bio_sim(:,3)>=bounding_box.Pmin-bounding_box.Tolerance),:)=1;
    output_thresholded_to_min_outpout= reshape(output_thresholded_to_min_outpout,r,c);
    bio_sim(find(bio_sim(:,3)<bounding_box.Pmin & bio_sim(:,3)>=bounding_box.Pmin-bounding_box.Tolerance),3)=bounding_box.Pmin;
    
    output_thresholded_to_max_outpout=0*bio_sim(:,3);
    output_thresholded_to_max_outpout(find(bio_sim(:,3)>bounding_box.Pmax & bio_sim(:,3)<=bounding_box.Pmax+bounding_box.Tolerance),:)=1;
    output_thresholded_to_max_outpout= reshape(output_thresholded_to_max_outpout,r,c);
    bio_sim(find(bio_sim(:,3)>bounding_box.Pmax & bio_sim(:,3)<=bounding_box.Pmax+bounding_box.Tolerance),3)=bounding_box.Pmax;     
    %% Creating output too low/high flag
    output_too_low=0*bio_sim(:,3);
    output_too_low(find(bio_sim(:,3)<bounding_box.Pmin-bounding_box.Tolerance),:)=1;
    output_too_low= reshape(output_too_low,r,c);

    output_too_high=0*bio_sim(:,3);
    output_too_high(find(bio_sim(:,3)>bounding_box.Pmax+bounding_box.Tolerance),:)=1;
    output_too_high= reshape(output_too_high,r,c);
    %% *********
    flags=(2^0)*input_out_of_range+(2^1)*output_thresholded_to_min_outpout+(2^2)*output_thresholded_to_max_outpout+...
        (2^3)*output_too_low+(2^4)*output_too_high;

    eval(['NNT_OUT.',lower(bio),'=reshape(bio_sim(:,3),r,c);']);
    eval(['NNT_OUT.',lower(bio),'_Uncertainties=reshape(bio_sim(:,4),r,c);']);
    eval(['NNT_OUT.',lower(bio),'_flags=flags;']);
    
    eval(['NNT_OUT.',lower(bio),'_input_out_of_range= input_out_of_range;']);
    eval(['NNT_OUT.',lower(bio),'_output_thresholded_to_min_outpout= output_thresholded_to_min_outpout;']);
    eval(['NNT_OUT.',lower(bio),'_output_thresholded_to_max_outpout= output_thresholded_to_max_outpout;']);
    eval(['NNT_OUT.',lower(bio),'_output_too_low= output_too_low;']);
    eval(['NNT_OUT.',lower(bio),'_output_too_high= output_too_high;']);
    %% exporting tif files
    bbox=Ib.BoundingBox;
    bit_depth=32;
    geotiffwrite([out_path,file_name,'_',lower(bio),'.tif'], bbox, eval(['NNT_OUT.',lower(bio)]), bit_depth, Ib);
    geotiffwrite([out_path,file_name,'_',lower(bio),'_uncertainties.tif'], bbox, eval(['NNT_OUT.',lower(bio),'_Uncertainties']), bit_depth, Ib);
    geotiffwrite([out_path,file_name,'_',lower(bio),'_flags.tif'], bbox, eval(['NNT_OUT.',lower(bio),'_flags']), bit_depth, Ib);        
end;
%% water_shadow_cloud_snow (WSCS) mask
file_name_band=dir([varargin{1},varargin{2},'\*pixel_qa*.tif']);
[band,xb,yb,Ib] = geoimread([varargin{1},varargin{2},'\',file_name_band(1).name]);
NNT_OUT.WSCS_mask=L8_OLI_WSCS_mask(band);
geotiffwrite([out_path,file_name,'_WSCS_mask.tif'], bbox, NNT_OUT.WSCS_mask, bit_depth, Ib);
save([out_path,strrep(file_name(1:end-1),'L2A','L2B'),'.mat'],'NNT_OUT','-v7.3');
close(h)
end


