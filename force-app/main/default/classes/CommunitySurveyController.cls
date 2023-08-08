public with sharing class CommunitySurveyController {
    
    /***************************************************
     * Get new survey response with survey answers
     * @param String recordId - Survey ID
     * @return Survey_Question__c[] collection of survey questions
     ***************************************************/
    @AuraEnabled(cacheable=true)
    public static List<SurveyQuestionWrapper> initializeSurvey(
        String recordId
    ) {
        List<SurveyQuestionWrapper> lstWrappers = new List<SurveyQuestionWrapper>();
        for (Survey_Question__c q : getSurveyQuestions(recordId)) {
            SurveyQuestionWrapper qWrap = new SurveyQuestionWrapper();
            qWrap.id = q.Id;
            qWrap.sortOrder = q.Sort_Order__c;
            qWrap.dataType = DataTypesUtil.getLightningInputType(q.Data_Type__c);
            qWrap.question = q.Question__c;
            qWrap.helpText = q.Help_Text__c;
            qWrap.isRequired = q.Required__c;
            qWrap.isHidden = q.Hidden__c;
            lstWrappers.add(qWrap);
        }
        return lstWrappers;
    }

    /************************************************************************
     * Save survey response and child survey answers
     * @param sObject[] records - Collection of answer objects to save
     * @return Id - Survey response id
     ************************************************************************/

     @AuraEnabled(cacheable=false)
     public static Id submitSurvey(
        String recordId, 
        String contactId, 
        List<sObject> answers
     ) {
        try {
            Survey_Response__c sr = new Survey_Response__c();
            sr.Survey__c = recordId;
            sr.Contact__c = contactId;
            Database.insert(
                sr, 
                false, 
                AccessLevel.USER_MODE
            );

            // Cast generic sObject to list of application answers
            List<Survey_Answer__c> lstAnswers = (List<Survey_Answer__c>) answers;
            for (Survey_Answer__c ans : lstAnswers) {
                ans.Survey_Response__c = sr.Id;
                // Convert lightning data type back to valid picklist value
                ans.Data_Type__c = DataTypesUtil.getDataTypeFromLightningInputType(ans.Data_Type__c);
            }

            // Update application answers
            Database.insert(
                lstAnswers,
                false,
                AccessLevel.USER_MODE
            );
            return sr.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    private static List<Survey_Question__c> getSurveyQuestions(
        String surveyId
    ) {
        return [
            SELECT Id,
                   Question__c,
                   Sort_Order__c,
                   Data_Type__c,
                   Help_Text__c,
                   Required__c,
                   Hidden__c
              FROM Survey_Question__c 
             WHERE Survey__c = :surveyId 
             ORDER BY Sort_Order__c ASC
             LIMIT 10000
        ];
    }

    /************************************************************************
     * Save survey response and child survey answers
     * @param sObject[] records - Collection of answer objects to save
     * @return Id - Survey response id
     ************************************************************************/

    public class SurveyQuestionWrapper {
        @AuraEnabled
        public Id id {get;set;}
        @AuraEnabled
        public Decimal sortOrder {get;set;}
        @AuraEnabled
        public String dataType {get;set;}
        @AuraEnabled
        public String question {get;set;}
        @AuraEnabled
        public String helpText {get;set;}
        @AuraEnabled
        public Boolean isRequired {get;set;}
        @AuraEnabled
        public Boolean isHidden {get;set;}
    }

}
