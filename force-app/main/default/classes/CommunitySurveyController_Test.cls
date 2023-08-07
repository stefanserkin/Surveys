@IsTest
private class CommunitySurveyController_Test {

    @TestSetup
    static void makeData() {
        Survey__c survey = TestDataFactory.createSurveys(
            1, 
            true
        ).get(0);

        List<Survey_Question__c> lstQuestions = TestDataFactory.createSurveyQuestions(
            survey.Id, 
            5, 
            true
        );
    }

    @IsTest 
    static void testInitializeSurvey() {
        Survey__c survey = [SELECT Id, (SELECT Id FROM Survey_Questions__r) FROM Survey__c LIMIT 1];
        List<Survey_Answer__c> lstAnswers;
        Test.startTest();
        lstAnswers = CommunitySurveyController.initializeSurvey(
            survey.Id
        );
        Test.stopTest();
        Assert.areEqual(
            survey.Survey_Questions__r.size(), 
            lstAnswers.size(), 
            'Should have received an answer for every question'
        );
    }

}
