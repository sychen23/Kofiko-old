function [strctOutput] = fnParadigmTouchShapesCycle(strctInputs)
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
% 8: monkey pushes wrong button



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
       fnFlipWrapper(g_strctStimulusServer.m_hWindow, 0, 0, 2); % Non blocking flip


        % Set ITI value
        fMin = fnTsGetVar(g_strctParadigm,'InterTrialIntervalMinSec');
        fMax = fnTsGetVar(g_strctParadigm,'InterTrialIntervalMaxSec');
        g_strctParadigm.m_fWaitInterval = rand() * (fMax-fMin) + fMin;
        g_strctParadigm.m_fTimer1 = fCurrTime;

        % Set Next Touch Position
        aiStimulusScreenSize = fnParadigmToKofikoComm('GetStimulusServerScreenSize');
        fSpotSizePix = fnTsGetVar(g_strctParadigm,'SpotRadius');

        % Set shape position
        fShapeSizePix = fnTsGetVar(g_strctParadigm, 'ShapeRadius');
        fShapeX = fShapeSizePix + 0.5 * (aiStimulusScreenSize(3) - 2 * fShapeSizePix);
        fShapeY = fShapeSizePix + 0.5 * (aiStimulusScreenSize(4) - 2 * fShapeSizePix);
        % Update shape position and size in structure
        g_strctParadigm.m_strctCurrentTrial.m_pt2fShapePos = [fShapeX,fShapeY];
        g_strctParadigm.m_strctCurrentTrial.m_fShapeRad = fShapeSizePix;
        
        %Set image position
        g_strctParadigm.m_strctCurrentTrial.m_pt2fImagePos = [fShapeX,fShapeY];
        g_strctParadigm.m_strctCurrentTrial.m_fImageRad = fShapeSizePix;
        
        % Set first spot position
        fSpotX = fSpotSizePix + 0.2 * (aiStimulusScreenSize(3) - 2 * fSpotSizePix);
        fSpotY = fSpotSizePix + 0.8 * (aiStimulusScreenSize(4) - 2 * fSpotSizePix);
        % Update spot 1 position and size in structure
        g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Green = [fSpotX,fSpotY];
        g_strctParadigm.m_strctCurrentTrial.m_fSpotRad = fSpotSizePix;

        % Change x for the second spot
        fSpotX = fSpotSizePix + 0.8 * (aiStimulusScreenSize(3) - 2 * fSpotSizePix);
        % Update spot 2 position and size in structure
        g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Red = [fSpotX, fSpotY];
        g_strctParadigm.m_strctCurrentTrial.m_fSpotRad = fSpotSizePix;
        
        % Chance swap coordinate positions of the dots if set to random
        if g_strctParadigm.m_bToggleRandomOrder
            if rand() > 0.5
                tempxy = g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Green;
                g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Green = g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Red;
                g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Red = tempxy;
            end
        end
        
        % assign a random image to be the next one. Check if the new image
        % matches the old one.
        imageArray = g_strctParadigm.m_fImageArray;
        if g_strctParadigm.m_strctStatistics.m_iNumTrials > 0
            g_strctParadigm.m_strctCurrentTrial.lastImageName = g_strctParadigm.m_strctCurrentTrial.imageName;
        else
            g_strctParadigm.m_strctCurrentTrial.lastImageName = '';
        end
        g_strctParadigm.m_strctCurrentTrial.imageName = imageArray(round(rand(1)*1) + 1, :);
        g_strctParadigm.m_strctCurrentTrial.matchingImage = ~strcmp(g_strctParadigm.m_strctCurrentTrial.lastImageName, ...
            g_strctParadigm.m_strctCurrentTrial.imageName)


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

          % Send a command to display the spot on the stimulus server
          % Randomly present image

          fFlipTime = fnDrawTwoSpotsAndShapeOnStimulusScreen(g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Red, ...
                                     g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Green, ...
                                     g_strctParadigm.m_strctCurrentTrial.m_pt2fShapePos,...
                                     g_strctParadigm.m_strctCurrentTrial.m_fSpotRad, ...
                                     g_strctParadigm.m_strctCurrentTrial.m_fImageRad, ...
                                     [255 0 0], [0 255 0], [255 255 0], ...
                                     g_strctParadigm.m_strctCurrentTrial.imageName,...
                                     g_strctParadigm.m_strctCurrentTrial.matchingImage);

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

                % Monkey touched the screen
                
                % green circle information
                fDistTouchToSpot_Green = sqrt(sum((strctInputs.m_pt2iEyePosScreen - g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Green).^2));
                fCorrectDist_Green = fnTsGetVar(g_strctParadigm, 'CorrectDistancePix');
                
                % red circle information
                fDistTouchToSpot_Red = sqrt(sum((strctInputs.m_pt2iEyePosScreen - g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Red).^2));
                fCorrectDist_Red = fnTsGetVar(g_strctParadigm, 'CorrectDistancePix');
                
                % shape information
                fDistTouchToShape = sqrt(sum((strctInputs.m_pt2iEyePosScreen - g_strctParadigm.m_strctCurrentTrial.m_pt2fShapePos).^2));
                fCorrectDist_Shape = fnTsGetVar(g_strctParadigm, 'CorrectDistancePix');                

                g_strctParadigm.m_strctCurrentTrial.m_fMonkeyTouch_TS = fCurrTime;
                g_strctParadigm.m_strctCurrentTrial.m_pt2fMonkeyTouchPos = strctInputs.m_pt2iEyePosScreen;
                % Monkey touched green circle - correct
                if fDistTouchToSpot_Green < fCorrectDist_Green
                    fnDoOnCorrect(fCurrTime)
                % Monkey touched red circle - wrong
                elseif fDistTouchToSpot_Red < fCorrectDist_Red
                    % If not reward both
                    if ~g_strctParadigm.m_bRewardBoth
                        % If not ignore wrong
                        if ~g_strctParadigm.m_bMultipleAttempts
                            fnDoOnWrong(fCurrTime)
                        end
                    % If reward both
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
        %wait Penalty time

        % fTimeout = fnTsGetVar(g_strctParadigm,'TrialTimeOutSec');
        % fPenalty_Time = 5;
        fPenalty_Time = fnTsGetVar(g_strctParadigm, 'PenaltySec');

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

function fnDrawShapeOnStimulusScreen(pt2iShape,fShapeSizePix,aiColor)
    global g_strctStimulusServer

return;

% Draws two spots with specified different positions and colors but same size.
function fFlipTime = fnDrawTwoSpotsAndShapeOnStimulusScreen(pt2iSpot_A, pt2iSpot_B, pt2iShape, ...
  fSpotSizePix, fShapeSizePix, aiColor_A, aiColor_B, aiColor_shape, imageName, matchingImage)
    global g_strctStimulusServer
    if matchingImage
        aiTouchSpotRect = [pt2iSpot_A(:)-fSpotSizePix;pt2iSpot_A(:)+fSpotSizePix];
        Screen(g_strctStimulusServer.m_hWindow,'FillArc',aiColor_A, aiTouchSpotRect,0,360);
    else
        aiTouchSpotRect = [pt2iSpot_B(:)-fSpotSizePix;pt2iSpot_B(:)+fSpotSizePix];
        Screen(g_strctStimulusServer.m_hWindow,'FillArc',aiColor_B, aiTouchSpotRect,0,360);
    end
    aiTouchShapeRect = [pt2iShape(:)-fShapeSizePix;pt2iShape(:)+fShapeSizePix];
    imageFile = strcat('images/', imageName);
    image = imread(imageFile, 'png');
%     resizedImage = imresize(image, [100 100], 'lanczos3');
    Screen('PutImage',g_strctStimulusServer.m_hWindow, image, aiTouchShapeRect);
%     Screen(g_strctStimulusServer.m_hWindow,'FillArc',aiColor_shape, aiTouchShapeRect,0,360);
    fFlipTime = fnFlipWrapper( g_strctStimulusServer.m_hWindow);%, 0, 0, 1); % Non blocking flip
return;

% Deals with a correct trial
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
    fnDrawTwoSpotsAndShapeOnStimulusScreen(g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Red, ...
                                     g_strctParadigm.m_strctCurrentTrial.m_pt2fSpotPos_Green, ...
                                     g_strctParadigm.m_strctCurrentTrial.m_pt2fShapePos,...
                                     g_strctParadigm.m_strctCurrentTrial.m_fSpotRad, ...
                                     g_strctParadigm.m_strctCurrentTrial.m_fImageRad, ...
                                     [255 0 0], [0 255 0], [255 255 0],...
                                     g_strctParadigm.m_strctCurrentTrial.imageName,...
                                     g_strctParadigm.m_strctCurrentTrial.matchingImage);

    fJuiceTimeMS = fnTsGetVar(g_strctParadigm, 'JuiceTimeMS');
    fnParadigmToKofikoComm('Juice',  fJuiceTimeMS);
    g_strctParadigm.m_iMachineState = 7; % Wait for monkey release
return
    
% Deals with an incorrect trial
function fnDoOnWrong(fCurrTime)
    global g_strctParadigm  g_strctStimulusServer

    % Incorrect trial
    if g_strctParadigm.m_bPlayIncorrect
        wavplay(g_strctParadigm.m_afIncorrectTrialSound, g_strctParadigm.m_fAudioSamplingRate,'async');
    end
    g_strctParadigm.m_strctStatistics.m_iNumIncorrect=g_strctParadigm.m_strctStatistics.m_iNumIncorrect+1;

    g_strctParadigm.m_strctCurrentTrial.m_strResult = 'Incorrect';
    fnTsSetVarParadigm('acTrials', g_strctParadigm.m_strctCurrentTrial);
    g_strctParadigm.m_iMachineState = 8;

    g_strctParadigm.m_strctCurrentTrial.m_fSpotRad = 0;

    % Clear Stimulus Screen
    fnFlipWrapper(g_strctStimulusServer.m_hWindow, 0, 0, 2); % Non blocking flip
    fnParadigmToKofikoComm('CriticalSectionOff');
    g_strctParadigm.m_fTimer_Penalty = fCurrTime;
return
