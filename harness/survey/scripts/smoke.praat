include eml-extract.praat
include eml-inferential.praat
include eml-analysis.praat
include eml-psychometrics.praat

dataT = Read Table from comma-separated file: "../../../evidence/csv/lane_survey_declared_data.csv"
scalesT = Read Table from comma-separated file: "../../../evidence/csv/lane_survey_declared_scales.csv"
itemsT = Read Table from comma-separated file: "../../../evidence/csv/lane_survey_declared_items.csv"

@emlSurveyValidateDeclaration: dataT, scalesT, itemsT
writeInfoLine: "refusal|", emlSurveyValidateDeclaration.refusal, "|", emlSurveyValidateDeclaration.error$

if emlSurveyValidateDeclaration.refusal = 0
    @emlSurveyScoreScales: dataT
    appendInfoLine: "confidence|", emlSurveyScoreScales.confidence
    for s from 1 to emlSurveyScoreScales.nScales
        name$ = emlSurveyValidateDeclaration.scaleName$[s]
        appendInfoLine: "SUB|", name$, "|k=", emlSurveyScoreScales.subK[s],
        ... "|alpha=", emlSurveyScoreScales.subAlpha[s],
        ... "|lo=", emlSurveyScoreScales.subCiLow[s],
        ... "|hi=", emlSurveyScoreScales.subCiHigh[s],
        ... "|n=", emlSurveyScoreScales.subN[s],
        ... "|nExcl=", emlSurveyScoreScales.subNExcluded[s],
        ... "|alphaErr=", emlSurveyScoreScales.subAlphaError$[s],
        ... "|deltaMax=", emlSurveyScoreScales.subDeltaMax[s],
        ... "|deltaMaxRow=", emlSurveyScoreScales.subDeltaMaxRow[s],
        ... "|infErr=", emlSurveyScoreScales.subInfluenceError$[s],
        ... "|scoredN=", emlSurveyScoreScales.subScoredN[s],
        ... "|scoredNone=", emlSurveyScoreScales.subScoredNone[s],
        ... "|scoreMean=", emlSurveyScoreScales.subScoreMean[s],
        ... "|scoreSD=", emlSurveyScoreScales.subScoreSD[s],
        ... "|scoreMin=", emlSurveyScoreScales.subScoreMin[s],
        ... "|scoreMax=", emlSurveyScoreScales.subScoreMax[s],
        ... "|isKR20=", emlSurveyScoreScales.subIsKR20[s]
        for j from 1 to emlSurveyScoreScales.subK[s]
            origIdx = emlSurveyScoreScales.subItemOrigIdx[s,j]
            iname$ = emlSurveyValidateDeclaration.itemName$[origIdx]
            appendInfoLine: "  ITEM|", iname$, "|drop=", emlSurveyScoreScales.subAlphaIfDeleted[s,j],
            ... "|rest=", emlSurveyScoreScales.subItemRest[s,j],
            ... "|tot=", emlSurveyScoreScales.subItemTotal[s,j],
            ... "|flag=", emlSurveyScoreScales.subItemFlag[s,j]
        endfor
    endfor
endif
