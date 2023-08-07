public with sharing class CommunitySurveyController {
    
    /***************************************************
     * Get new survey response with survey answers
     * @param String recordId - Survey ID
     * @return Survey_Answer__c[] collection of unsaved survey answers
     ***************************************************/
    @AuraEnabled(cacheable=true)
    public static List<Survey_Answer__c> initializeSurvey(
        String recordId
    ) {
        List<Survey_Answer__c> lstAs = new List<Survey_Answer__c>();

        List<Survey_Question__c> lstQs = getSurveyQuestions(recordId);
        for (Survey_Question__c q : lstQs) {
            lstAs.add(
                new Survey_Answer__c(
                    Survey_Question__c = q.Id,
                    Question__c = q.Question__c,
                    Data_Type__c = q.Data_Type__c,
                    Answer__c = ''
                )
            );
        }

        return lstAs;
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
            }
            // TODO - Perform validation

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
                   Help_Text__c
              FROM Survey_Question__c 
             WHERE Survey__c = :surveyId 
              WITH USER_MODE
             ORDER BY Sort_Order__c ASC
             LIMIT 10000
        ];
    }

}
