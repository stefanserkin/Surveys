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
        List<Survey_Answer__c> lstAnswers;
        Test.startTest();
        System.runAs(adminUser) {
            lstAnswers = CommunitySurveyController.initializeSurvey(
                survey.Id
            );
        }
        Test.stopTest();
        Assert.areEqual(
            survey.Survey_Questions__r.size(), 
            lstAnswers.size(), 
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
            List<Survey_Answer__c> lstAnswers = CommunitySurveyController.initializeSurvey(
                survey.Id
            );

            for (Survey_Answer__c ans : lstAnswers) {
                ans.Answer__c = 'Test Answer';
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
