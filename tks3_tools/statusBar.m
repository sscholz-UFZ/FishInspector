hFig = findall(0, 'parent', 0)
if isempty(hFig), hFig = figure; drawnow; pause(0.1); end
%
jFrame = get(hFig,'JavaFrame');

[statusbarObj, hm] = javacomponent('com.mathworks.mwswing.MJStatusBar', [0,0,100,100], hFig);
newLayout = java.awt.GridLayout(1,2);  % 2 rows, 3 cols
statusbarObj.setLayout(newLayout);
...  % add content to the statusbarObj container
    
rootPane = jFrame.fHG2Client.getWindow;  % See http://undocumentedmatlab.com/blog/hg2-update#observations item #2
rootPane.setStatusBar(statusbarObj);


jb = javax.swing.JLabel('MousePos');
jbh = handle(jb,'CallbackProperties');
statusbarObj.add(jb);


statusbarObj.setText('Hallo')



rootPane.setStatusBarVisible(0)
rootPane.setStatusBarVisible(1)

%% Status bar
bgcolor = [0,0,0];
%bgcolor = get(hFig, 'Color')
statusbarObj.setBackground(java.awt.Color(bgcolor(1),bgcolor(2),bgcolor(3)));

%% Text
comp = statusbarObj.getComponent(0);
bgcolor = [0,0,0];
comp.setBackground(java.awt.Color(bgcolor(1),bgcolor(2),bgcolor(3)));

%% Parent!
bgcolor = [0,0,0];
statusbarObj.getParent.setBackground(java.awt.Color(bgcolor(1),bgcolor(2),bgcolor(3)));

%%
jb = javax.swing.JButton('Next phase >');
jbh = handle(jb,'CallbackProperties');
set(jbh, 'ActionPerformedCallback', @nextPhaseFunction);
statusbarObj.getParent.add(jb,'East');

%%
bgcolor = [0,0,0];
jbordercolor = java.awt.Color(bgcolor(1),bgcolor(2),bgcolor(3));
border = javax.swing.BorderFactory.createLineBorder(jbordercolor)
statusbarObj.getParent.setBorder(border)

%%
handles = guidata(hFig);
path = handles.fishobj.impath;
fileURL = guitools.path2fileURL(path);
statusbarObj.setToolTipText(['<html><b>Bild:<br><br>',...
    '<img src="', fileURL, '" style="width:10%;height:10%;"/>',... height:228px;">',...
                             '</html>]']);




%%
% Add a "Next phase" button to the right of the text
jb = javax.swing.JButton('Next phase >');
jbh = handle(jb,'CallbackProperties');
set(jbh, 'ActionPerformedCallback', @nextPhaseFunction);
statusbarObj.add(jb,'East');
%note: we might need jRootPane.setStatusBarVisible(0)
% followed by jRootPane.setStatusBarVisible(1) to repaint
 