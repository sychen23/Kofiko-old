function [strctOutput] = fnParadigmTouchScreenCycle(strctInputs)
%
% Copyright (c) 2008 Shay Ohayon, California Institute of Technology.
% This file is a part of a free software. you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation (see GPL.txt)

global g_strctParadigm  g_strctStimulusServer



% 0: wait until user click start
% 1: decide trial parameters (where next point is going to appear, etc)
% 2: monkey initiates trials version: wait until monkey touch the screen
% 3: monkey initiates trials version: wait until monkey releases touch
% 4: Display dot on screen
% 5: wait until timeout or monkey touches the screen, give juice if correct
% 7: wait until monkey releases touch



fCurrTime = GetSecs();
switch g_strctParadigm.m_iMachineState
    case 0
        if ~isfield(g_strctStimulusServer,'m_hWindow')
            fnParadigmToKofikoComm('SetParadigmState','This paradigm is coded for a single computer setup');
        else
            fnParadigmToKofikoComm('SetParadigmState','Waiting for user to press Start');
        end
        
    case 1
        % Clear Stimulus Screen
        %fnFlipWrapper(g_strctStimulusServer.m_hWindow, 0, 0, 2); % Non blocking flip
        
        
        % Set ITI value
        fMin = fnTsGetVar(g_strctParadigm,'InterTrialIntervalMinSec');
        fMax = fnTsGetVar(g_strctParadigm,'InterTrialIntervalMaxSec');
        g_strctParadigm.m_fWaitInterval = rand() * (fMax-fMin) + fMin;
        g_strctParadigm.m_fTimer1 = fCurrTime;
        % Set Next Touch Position
        aiStimulusScreenSize = fnParadigmToKofikoComm('GetStimulusServerScreenSize');
        
        
        fSpotSizePix = fnTsGetVar(g_strctParadigm,'SpotRadius');
        %set first spot position
        fSpotX = fSpotSizePix + 0.2*(aiStimulusScreenSize(3)-2*fSpotSizePix);
        fSpotY = fSpotSizePix + 0.8*(aiStimulusScreenSize(4)-2*fSpotSizePix);
        %update spot 1 position and size in structure
        g_strctParadigm.m_strctCurrentTrial.m_fSpotRad = fSpotSizePix;
        g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Green = [fSpotX,fSpotY];
        %change x for the second spot
        fSpotX = fSpotSizePix + 0.8*(aiStimulusScreenSize(3)-2*fSpotSizePix);
        %update spot 2 position and size in structure
        g_strctParadigm.m_strctCurrentTrial.m_fSpotRad = fSpotSizePix;
        g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Red = [fSpotX,fSpotY];
        
        %flip coordinates around if set to random
        if g_strctParadigm.m_bToggleRandomOrder
            if rand() > 0.5
                tempxy = g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Green;
                g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Green = g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Red;
                g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Red = tempxy;
            end
        end
        
        if ~g_strctParadigm.m_bMonkeyInitiatesTrials
            g_strctParadigm.m_iMachineState = 4;
        else
            g_strctParadigm.m_iMachineState = 2;
            g_strctParadigm.m_fWaitInterval = 0;
            g_strctParadigm.m_fMin = fnTsGetVar(g_strctParadigm,'InterTrialIntervalMinSec');
        end
    case 2
        
        % Monkey initiates trials. Wait until he presses a key.
        if fCurrTime - g_strctParadigm.m_fTimer1 < g_strctParadigm.m_fMin
            fnParadigmToKofikoComm('SetParadigmState', sprintf('Intertrial wait (%d) sec',round(g_strctParadigm.m_fMin- (fCurrTime - g_strctParadigm.m_fTimer1))));
        else
            fnParadigmToKofikoComm('SetParadigmState', 'Waiting for monkey to initiate trial');
        end
        
        if strctInputs.m_abMouseButtons(1)
            g_strctParadigm.m_iMachineState = 3;
            fnParadigmToKofikoComm('SetParadigmState', 'Waiting for monkey release');
            
        end
        
    case 3
        if ~strctInputs.m_abMouseButtons(1)
            g_strctParadigm.m_iMachineState = 4;
        end
    case 4
        if fCurrTime - g_strctParadigm.m_fTimer1 > g_strctParadigm.m_fWaitInterval
            % Trial Started
            g_strctParadigm.m_strctStatistics.m_iNumTrials = g_strctParadigm.m_strctStatistics.m_iNumTrials + 1;
            
            fFlipTime = fnDrawTwoSpotsOnStimulusScreen(g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Red, ...
                g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Green, g_strctParadigm.m_strctCurrentTrial.m_fSpotRad, ...
                [255 0 0],[0 255 0]);
            
            g_strctParadigm.m_strctCurrentTrial.m_fSpotOnset_TS = fFlipTime;
            fnParadigmToKofikoComm('CriticalSectionOn');
            % Play trial onset
            if g_strctParadigm.m_bPlayTrialOnset
                wavplay(g_strctParadigm.m_afTrialOnsetSound, g_strctParadigm.m_fAudioSamplingRate,'async');
            end
            
            g_strctParadigm.m_fTimer2 = fCurrTime;
            g_strctParadigm.m_iMachineState = 5;
        else
            % Still in Inter Trial Interval. If monkey press the screen,
            % reset the ITI timer.
            if strctInputs.m_abMouseButtons(1)
                g_strctParadigm.m_fTimer1 = fCurrTime;
            else
                fnParadigmToKofikoComm('SetParadigmState',...
                    sprintf('Next trial starts in %d sec',round(g_strctParadigm.m_fWaitInterval - (fCurrTime - g_strctParadigm.m_fTimer1) )));
            end
        end
    case 5
        fTimeout = fnTsGetVar(g_strctParadigm,'TrialTimeOutSec');
        if fCurrTime - g_strctParadigm.m_fTimer2 > fTimeout
            % Timeout!
            g_strctParadigm.m_strctCurrentTrial.m_strResult = 'TimeOut';
            g_strctParadigm.m_strctStatistics.m_iNumTimeout = g_strctParadigm.m_strctStatistics.m_iNumTimeout +1;
            g_strctParadigm.m_strctCurrentTrial.m_fTrialEnd_TS = fCurrTime;
            fnTsSetVarParadigm('acTrials', g_strctParadigm.m_strctCurrentTrial);
            
            % Play trial timeout
            if g_strctParadigm.m_bPlayTrialOnset
                wavplay(g_strctParadigm.m_afTrialOnsetSound, g_strctParadigm.m_fAudioSamplingRate,'async');
            end
            % Goto 1
            fnParadigmToKofikoComm('CriticalSectionOff');
            g_strctParadigm.m_iMachineState = 1;
        else
            fnParadigmToKofikoComm('SetParadigmState',...
                sprintf('Waiting for response. Timeout in %d sec',round(fTimeout - (fCurrTime - g_strctParadigm.m_fTimer2))));
            if strctInputs.m_abMouseButtons(1)
                
               
                fDistTouchToSpot_Green = sqrt(sum((strctInputs.m_pt2iEyePosScreen - g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Green).^2));
                fCorrectDist_Green = fnTsGetVar(g_strctParadigm, 'CorrectDistancePix');
                %monkey touched red circle - correct
                fDistTouchToSpot_Red = sqrt(sum((strctInputs.m_pt2iEyePosScreen - g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Red).^2));
                fCorrectDist_Red = fnTsGetVar(g_strctParadigm, 'CorrectDistancePix');
                
                
                g_strctParadigm.m_strctCurrentTrial.m_fMonkeyTouch_TS = fCurrTime;
                g_strctParadigm.m_strctCurrentTrial.m_pt2fMonkeyTouchPos = strctInputs.m_pt2iEyePosScreen;
                
               
                %monkey touched green circle 
                if fDistTouchToSpot_Green < fCorrectDist_Green
                     fnDoOnCorrect(fCurrTime)
                      
                %monkey touched red circle
                elseif fDistTouchToSpot_Red < fCorrectDist_Red
                    %if not reward both
                    if ~g_strctParadigm.m_bRewardBoth
                        %if not ignore wrong
                        if ~g_strctParadigm.m_bMultipleAttempts
                            fnDoOnWrong(fCurrTime)
                        end
                    %if reward both
                    else
                       fnDoOnCorrect(fCurrTime) 
                    end
                end
            end
        end
        
    case 7
        if ~strctInputs.m_abMouseButtons(1)
            g_strctParadigm.m_iMachineState = 1; % Start a new trial
            fnParadigmToKofikoComm('CriticalSectionOff');
        end
        
    case 8
        %Penalty
        
        % fTimeout = fnTsGetVar(g_strctParadigm,'TrialTimeOutSec');
        fPenalty_Time = fnTsGetVar(g_strctParadigm,'PenaltySec');
        
        if fCurrTime - g_strctParadigm.m_fTimer_Penalty < fPenalty_Time
            fnParadigmToKofikoComm('SetParadigmState',...
                sprintf('Waiting for penalty delay %d sec',round(fPenalty_Time - (fCurrTime - g_strctParadigm.m_fTimer_Penalty))));
            
        else
            g_strctParadigm.m_iMachineState = 1;
            fnParadigmToKofikoComm('SetParadigmState', 'Waiting for monkey to initiate trial');
        end
        
        
        
end;


strctOutput = strctInputs;
return;

function fFlipTime = fnDrawSpotOnStimulusScreen(pt2iSpot,fSpotSizePix,aiColor)
global g_strctStimulusServer
aiTouchSpotRect = [pt2iSpot(:)-fSpotSizePix;pt2iSpot(:)+fSpotSizePix];
Screen(g_strctStimulusServer.m_hWindow,'FillArc',aiColor, aiTouchSpotRect,0,360);
fFlipTime = fnFlipWrapper2( g_strctStimulusServer.m_hWindow);%, 0, 0, 1); % Non blocking flip
return;


function fFlipTime = fnDrawTwoSpotsOnStimulusScreen(pt2iSpot_A,pt2iSpot_B, fSpotSizePix,aiColor_A,aiColor_B)
global g_strctStimulusServer
aiTouchSpotRect = [pt2iSpot_A(:)-fSpotSizePix;pt2iSpot_A(:)+fSpotSizePix];
Screen(g_strctStimulusServer.m_hWindow,'FillArc',aiColor_A, aiTouchSpotRect,0,360);
aiTouchSpotRect = [pt2iSpot_B(:)-fSpotSizePix;pt2iSpot_B(:)+fSpotSizePix];
Screen(g_strctStimulusServer.m_hWindow,'FillArc',aiColor_B, aiTouchSpotRect,0,360);
fFlipTime = fnFlipWrapper2( g_strctStimulusServer.m_hWindow);%, 0, 0, 1); % Non blocking flip
return;


function fnDoOnCorrect(fCurrTime)
global g_strctParadigm
g_strctParadigm.m_strctCurrentTrial.m_strResult = 'Correct';
g_strctParadigm.m_strctCurrentTrial.m_fTrialEnd_TS = fCurrTime;
fnTsSetVarParadigm('acTrials', g_strctParadigm.m_strctCurrentTrial);
% Correct trial
if g_strctParadigm.m_bPlayCorrect
    wavplay(g_strctParadigm.m_afCorrectSound, g_strctParadigm.m_fAudioSamplingRate,'async');
end
g_strctParadigm.m_strctStatistics.m_iNumCorrect  = g_strctParadigm.m_strctStatistics.m_iNumCorrect  + 1;
fnParadigmToKofikoComm('SetParadigmState', 'Correct Trial. Waiting for release');
% Show OK to release stimulus
fFlipTime =  fnDrawTwoSpotsOnStimulusScreen(g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Red, ...
    g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Green, g_strctParadigm.m_strctCurrentTrial.m_fSpotRad, ...
    [255 255 255],[255 255 255]);
fJuiceTimeMS = fnTsGetVar(g_strctParadigm, 'JuiceTimeMS');
fnParadigmToKofikoComm('Juice',  fJuiceTimeMS);
g_strctParadigm.m_iMachineState = 7; % Wait for monkey release
return

function fnDoOnWrong(fCurrTime)
global g_strctParadigm  g_strctStimulusServer
% inCorrect trial
if g_strctParadigm.m_bPlayIncorrect
    wavplay(g_strctParadigm.m_afIncorrectTrialSound, g_strctParadigm.m_fAudioSamplingRate,'async');
end
g_strctParadigm.m_strctStatistics.m_iNumIncorrect=g_strctParadigm.m_strctStatistics.m_iNumIncorrect+1;
g_strctParadigm.m_strctCurrentTrial.m_strResult = 'Incorrect';
fnTsSetVarParadigm('acTrials', g_strctParadigm.m_strctCurrentTrial);
g_strctParadigm.m_iMachineState = 8;
g_strctParadigm.m_strctCurrentTrial.m_fSpotRad = 0;
% Clear Stimulus Screen
fnFlipWrapper2(g_strctStimulusServer.m_hWindow, 0, 0, 2); % Non blocking flip
fnParadigmToKofikoComm('CriticalSectionOff');
g_strctParadigm.m_fTimer_Penalty = fCurrTime;
return

function fFlipTime = fnFlipWrapper2(hWindow, varargin)
%modified function that just sets the rectangle used to measure screen
%onset to size 0 (without having to change the main function that isn't
%part of a paradigm.
% A wrapper function to Screen('Flip')
% used to draw a small rectangle (either black or white) just prior to the flip
% to obtain the most accurate time stamp from a photodiode attached to the
% screen....
% This is to adjust for LCD lag time (which can range between 10-20 ms...)
%
global g_bPhotoDiodeToggle
iRectSizePix = 0;
if isempty(g_bPhotoDiodeToggle) || ~g_bPhotoDiodeToggle
    g_bPhotoDiodeToggle = true;
    % Draw the small white rectangle
    Screen('FillRect', hWindow, [255 255 255],[0 0 iRectSizePix iRectSizePix]);
else
    g_bPhotoDiodeToggle = false;
    % Draw the small black rectangle
    Screen('FillRect', hWindow, [0 0 0],[0 0 iRectSizePix iRectSizePix]);
end
fFlipTime = Screen('Flip', hWindow, varargin{:});
return;