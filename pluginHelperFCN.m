function plugins = pluginHelperFCN(fishObj)
% Automatically created Helper-FCN necessary for deployment.
% Do not edit
% 05 - 06/2016
% TobiasKiessling@tks3.de

    plugins(1) = markup_fishPlugin(fishObj, 'getFishPlugin');
    plugins(2) = capillary_fishPlugin(fishObj, 'getFishPlugin');
    plugins(3) = fishContour_fishPlugin(fishObj, 'getFishPlugin');
    plugins(4) = fishEye_fishPlugin(fishObj, 'getFishPlugin');
    plugins(5) = fishOrientation_fishPlugin(fishObj, 'getFishPlugin');
    plugins(6) = centralDarkLine_fishPlugin(fishObj, 'getFishPlugin');
    plugins(7) = bladder_fishPlugin(fishObj, 'getFishPlugin');
    plugins(8) = notochord_fishPlugin(fishObj, 'getFishPlugin');
    plugins(9) = otolith_fishPlugin(fishObj, 'getFishPlugin');
    plugins(10) = yolk_fishPlugin(fishObj, 'getFishPlugin');
    plugins(11) = pericard_fishPlugin(fishObj, 'getFishPlugin');
    plugins(12) = pigmentation_fishPlugin(fishObj, 'getFishPlugin');
