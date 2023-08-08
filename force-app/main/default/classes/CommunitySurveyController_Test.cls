@IsTest
private class CommunitySurveyController_Test {

    @TestSetup
    static void makeData() {
        User u = TestDataFactory.createUser('Admin');

        System.runAs(u) {
            Survey__c survey = TestDataFactory.createSurveys(
                1, 
                true
            ).get(0);

            List<Survey_Question__c> lstQuestions = TestDataFactory.createSurveyQuestions(
                survey.Id, 
                5, 
                true
            );

            Contact ct = TestDataFactory.createContacts(
                1, 
                true
            ).get(0);
        }

    }

    @IsTest 
    static void testInitializeSurvey() {
        User adminUser = [
            SELECT Id 
              FROM User 
             WHERE Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Surveys_Admin')
             LIMIT 1
        ];
        Survey__c survey = [
            SELECT Id, 
                   (SELECT Id FROM Survey_Questions__r) 
              FROM Survey__c 
             LIMIT 1
        ];
        List<CommunitySurveyController.SurveyQuestionWrapper> lstWrappers;
        Test.startTest();
        System.runAs(adminUser) {
            lstWrappers = CommunitySurveyController.initializeSurvey(
                survey.Id
            );
        }
        Test.stopTest();
        Assert.areEqual(
            survey.Survey_Questions__r.size(), 
            lstWrappers.size(), 
            'Should have received an answer for every question'
        );
    }

    @IsTest
    static void testSubmitSurvey() {
        User adminUser = [
            SELECT Id 
              FROM User 
             WHERE Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Surveys_Admin')
             LIMIT 1
        ];
        
        Survey__c survey = [
            SELECT Id, 
                   (SELECT Id FROM Survey_Questions__r) 
              FROM Survey__c 
             LIMIT 1
        ];

        Contact ct = [SELECT Id FROM Contact LIMIT 1];

        Id surveyResponseId;

        Test.startTest();
        System.runAs(adminUser) {
            List<Survey_Answer__c> lstAnswers = new List<Survey_Answer__c>();
            List<CommunitySurveyController.SurveyQuestionWrapper> lstWrappers;
            lstWrappers = CommunitySurveyController.initializeSurvey(
                survey.Id
            );

            for (CommunitySurveyController.SurveyQuestionWrapper q : lstWrappers) {
                lstAnswers.add(
                    new Survey_Answer__c(
                        Survey_Question__c = q.id,
                        Question__c = q.question,
                        Data_Type__c = q.dataType,
                        Answer__c = 'Test Answer'
                    )
                );
            }
        
            surveyResponseId = CommunitySurveyController.submitSurvey(
                survey.Id, 
                ct.Id, 
                lstAnswers
            );
        }
        Test.stopTest();

        Survey_Response__c response = [
            SELECT Id,
                   (SELECT Id FROM Survey_Answers__r)
              FROM Survey_Response__c
             WHERE Id = :surveyResponseId
             LIMIT 1
        ];

        Assert.areEqual(
            survey.Survey_Questions__r.size(), 
            response.Survey_Answers__r.size(), 
            'Should have received an answer for every question'
        );
    }

}
