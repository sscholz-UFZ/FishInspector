function hf = figure(varargin)
% FIGURE(varargin)
% Wrapper function to builtin figure-function, to include a nwe icon to
% each and every figure that is created.
%
% Scientific Software Solutions
% Tobias Kieﬂling 01/2013-08/2016
% support@tks3.de


% Disable annoying warnings
warning('off', 'MATLAB:dispatcher:nameConflict');
warning('off', 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');

% Call the builtin figure function
hf = builtin('figure', varargin{:});

% Replace standarad MATALB icon
file = fullfile(guitools.getCurrentDir(), 'icon_48.png');
if exist(file, 'file')==2
    jframe=get(hf, 'javaframe');
    jIcon=javax.swing.ImageIcon(file);
    jframe.setFigureIcon(jIcon);
end