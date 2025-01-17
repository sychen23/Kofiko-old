function fnParadigmTouchShapesDraw()
%
% Copyright (c) 2008 Shay Ohayon, California Institute of Technology.
% This file is a part of a free software. you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation (see GPL.txt)
%
global g_strctPTB g_strctParadigm
% Do not call Flip, just draw everything to the screen.
if g_strctParadigm.m_iMachineState > 4
    fSpotSizePix = g_strctParadigm.m_strctCurrentTrial.m_fSpotRad;
    fShapeSizePix = g_strctParadigm.m_strctCurrentTrial.m_fShapeRad;
    
    fCorrectDist = fnTsGetVar(g_strctParadigm, 'CorrectDistancePix');
    
    %first show green spot and boundaries
    pt2iSpot = g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Green(:);
    aiColor = [0 255 0];
    aiTouchSpotRect = g_strctPTB.m_fScale * [pt2iSpot-fSpotSizePix;pt2iSpot+fSpotSizePix];
    aiValidRect = g_strctPTB.m_fScale * [pt2iSpot-fCorrectDist;pt2iSpot+fCorrectDist];
       
    Screen(g_strctPTB.m_hWindow,'FillArc',aiColor, aiTouchSpotRect,0,360);
    Screen(g_strctPTB.m_hWindow,'FrameArc',aiColor, aiValidRect,0,360);
    
    %then show red spot and boundaries
    pt2iSpot = g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Red(:);
    aiColor = [255 0 0];
    aiTouchSpotRect = g_strctPTB.m_fScale * [pt2iSpot-fSpotSizePix;pt2iSpot+fSpotSizePix];
    aiValidRect = g_strctPTB.m_fScale * [pt2iSpot-fCorrectDist;pt2iSpot+fCorrectDist];

    Screen(g_strctPTB.m_hWindow,'FillArc',aiColor, aiTouchSpotRect,0,360);
    Screen(g_strctPTB.m_hWindow,'FrameArc',aiColor, aiValidRect,0,360);

    %then show shape and boundaries
    pt2iShape = g_strctParadigm.m_strctCurrentTrial.m_pt2fShapePos(:);
    aiColor = [255 255 0];
    aiTouchShapeRect = g_strctPTB.m_fScale * [pt2iShape-fShapeSizePix;pt2iShape+fShapeSizePix];
    aiValidRect = g_strctPTB.m_fScale * [pt2iShape-fCorrectDist;pt2iShape+fCorrectDist];

    %Screen(g_strctPTB.m_hWindow,'FillArc',aiColor, aiTouchShapeRect,0,360);
    %Screen(g_strctPTB.m_hWindow,'FrameArc',aiColor, aiValidRect,0,360);
    
<<<<<<< HEAD
    imageFile = strcat('images/', g_strctParadigm.m_strctCurrentTrial.imageName);
=======
    imageFile = 'images/circle.png';
>>>>>>> 4b6f317a9ada562988f3b3c0bd075d12bd7f449b
    image = imread(imageFile, 'png');
%     resizedImage = imresize(image, [100 100], 'lanczos3');
%     Screen('MakeTexture', g_strctPTB.m_hWindow, image, aiValidRect);
    Screen('PutImage',g_strctPTB.m_hWindow, image, aiValidRect);

    
    
    
end   

fStartX = 400;
fStartY = 20;
Screen(g_strctPTB.m_hWindow,'DrawText', sprintf('Num Trials : %d',g_strctParadigm.m_strctStatistics.m_iNumTrials), fStartX,fStartY,[255 255 255]);
Screen(g_strctPTB.m_hWindow,'DrawText', sprintf('Correct    : %d',g_strctParadigm.m_strctStatistics.m_iNumCorrect), fStartX,fStartY+30,[0 255 0]);
Screen(g_strctPTB.m_hWindow,'DrawText', sprintf('Incorrect  : %d',g_strctParadigm.m_strctStatistics.m_iNumIncorrect), fStartX,fStartY+60,[255 0 0]);
Screen(g_strctPTB.m_hWindow,'DrawText', sprintf('Timeout    : %d',g_strctParadigm.m_strctStatistics.m_iNumTimeout), fStartX,fStartY+90,[255 0 255]);

%% Running performance

%fnDrawRunningPerformance();
return;

