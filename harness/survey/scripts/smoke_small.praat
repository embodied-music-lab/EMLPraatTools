include eml-extract.praat
include eml-inferential.praat
include eml-analysis.praat
include eml-psychometrics.praat

dataT = Read Table from comma-separated file: "../fixtures/small_data.csv"
scalesT = Read Table from comma-separated file: "../../../evidence/csv/lane_survey_declared_scales.csv"
itemsT = Read Table from comma-separated file: "../../../evidence/csv/lane_survey_declared_items.csv"

@emlSurveyValidateDeclaration: dataT, scalesT, itemsT
writeInfoLine: "refusal|", emlSurveyValidateDeclaration.refusal, "|", emlSurveyValidateDeclaration.error$

if emlSurveyValidateDeclaration.refusal = 0
    @emlSurveyScoreScales: dataT
    for s from 1 to emlSurveyScoreScales.nScales
        name$ = emlSurveyValidateDeclaration.scaleName$[s]
        appendInfoLine: "SUB|", name$, "|k=", emlSurveyScoreScales.subK[s],
        ... "|alpha=", emlSurveyScoreScales.subAlpha[s],
        ... "|n=", emlSurveyScoreScales.subN[s],
        ... "|nExcl=", emlSurveyScoreScales.subNExcluded[s],
        ... "|alphaErr=", emlSurveyScoreScales.subAlphaError$[s],
        ... "|infErr=", emlSurveyScoreScales.subInfluenceError$[s],
        ... "|scoredN=", emlSurveyScoreScales.subScoredN[s],
        ... "|scoreMean=", emlSurveyScoreScales.subScoreMean[s]
    endfor
endif
