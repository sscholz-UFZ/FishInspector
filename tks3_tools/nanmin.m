function [varargout] = nanmin(varargin)
%NANMIN Wrapper function for min to get the minimum value(s) while ignoring NaNs.
[varargout{1:nargout}] = min(varargin{:});
