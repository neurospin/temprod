function varargout = spm_project(varargin)
% forms maximium intensity projections - a compiled routine
% FORMAT spm_project(X,L,dims)
% X	-	a matrix of voxel values
% L	- 	a matrix of locations in Talairach et Tournoux (1988) space
% dims  -       assorted dimensions.
%               dims(1:3) - the sizes of the projected rectangles.
%               dims(4:5) - the dimensions of the mip image.
%_______________________________________________________________________
%
% spm_project 'fills in' a matrix (SPM) in the workspace to create
% a maximum intensity projection according to a point list of voxel
% values (V) and their locations (L) in the standard space described
% in the atlas of Talairach & Tournoux (1988).
%
% see also spm_mip.m
%
%_______________________________________________________________________
% @(#)spm_project.m	2.2 FIL 99/04/19

%-This is merely the help file for the compiled routine
error('spm_project.c not compiled - see spm_MAKE.sh')
