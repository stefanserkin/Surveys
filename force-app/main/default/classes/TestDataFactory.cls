public class TestDataFactory {

    private static List<String> cachedQuestionDataTypes;

    /******************************
     * Constants
     ******************************/
    private static final String SURVEY_NAME_BASE = 'Test Survey';
    private static final String SURVEY_QUESTION_BASE = 'Who what when where why';
    
    /******************************
     * Get survey sobjects
     * @param Integer numberOfRecords - Number of sobjects to create
     * @param Boolean doCommit - Set to true to save records before returning to caller
     * @return Survey__c[] Collection of surveys
     ******************************/
    public static List<Survey__c> createSurveys(
        Integer numberOfRecords,
        Boolean doCommit
    ) {
        List<Survey__c> lstSurveys = new List<Survey__c>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            lstSurveys.add(
                new Survey__c(Name = SURVEY_NAME_BASE + ' ' + String.valueOf(i))
            );
        }
        if (doCommit) {
            lstSurveys = commitRecords(lstSurveys);
        }
        return lstSurveys;
    }

    /******************************
     * Get survey question sobjects
     * @param Id surveyId - Record id of the parent survey
     * @param Integer numberOfRecords - Number of sobjects to create
     * @param Boolean doCommit - Set to true to save records before returning to caller
     * @return Survey_Question__c[] Collection of survey questions
     ******************************/
    public static List<Survey_Question__c> createSurveyQuestions(
        Id surveyId,
        Integer numberOfRecords,
        Boolean doCommit
    ) {
        List<Survey_Question__c> lstQuestions = new List<Survey_Question__c>();
        List<String> lstDataTypes = getQuestionDataTypes();
        for (Integer i = 0; i < numberOfRecords; i++) {
            // Cycle through available data types
            String dataType = lstDataTypes.size() > i + 1 
                ? lstDataTypes.get(i) 
                : lstDataTypes.get( Math.mod(i, lstDataTypes.size()) );
            lstQuestions.add(
                new Survey_Question__c(
                    Survey__c = surveyId,
                    Data_Type__c = dataType,
                    Question__c = SURVEY_QUESTION_BASE + ' ' + String.valueOf(i) + '?'
                )
            );
        }
        if (doCommit) {
            lstQuestions = commitRecords(lstQuestions);
        }
        return lstQuestions;
    }

    private static List<String> getQuestionDataTypes() {
        if (cachedQuestionDataTypes == null) {
            cachedQuestionDataTypes = new List<String>();
            Schema.DescribeFieldResult fieldResult = Survey_Question__c.Data_Type__c.getDescribe();
            List<Schema.PicklistEntry> lstEntries = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry val : lstEntries){
                cachedQuestionDataTypes.add(val.getLabel());
            }
        }
        return cachedQuestionDataTypes;
    }

    /******************************
     * DML
     ******************************/
    private static List<SObject> commitRecords(List<SObject> lstObjects) {
        Database.upsert(lstObjects, AccessLevel.SYSTEM_MODE);
        return lstObjects;
    }

}