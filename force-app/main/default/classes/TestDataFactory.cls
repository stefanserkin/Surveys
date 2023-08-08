@IsTest
public class TestDataFactory {

    private static List<String> cachedQuestionDataTypes;

    /******************************
     * Constants
     ******************************/
    private static final String SURVEY_NAME_BASE = 'Test Survey';
    private static final String SURVEY_QUESTION_BASE = 'Who what when where why';


    /******************************
     * Contacts
     ******************************/

    /******************************
     * Get contact sobjects
     * @param Integer numberOfRecords - Number of sobjects to create
     * @param Boolean doCommit - Set to true to save records before returning to caller
     * @return Contact[] Collection of contacts
     ******************************/
    public static List<Contact> createContacts(
        Integer numberOfRecords,
        Boolean doCommit
    ) {
        List<Contact> lstContacts = new List<Contact>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            lstContacts.add(
                new Contact(
                    FirstName = 'Test' + String.valueOf(i),
                    LastName = 'Tester'
                )
            );
        }
        if (doCommit) {
            lstContacts = commitRecords(lstContacts);
        }
        return lstContacts;
    }


    /******************************
     * Surveys
     ******************************/
    
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
                new Survey__c(
                    Name = SURVEY_NAME_BASE + ' ' + String.valueOf(i),
                    Paginated__c = true,
                    Max_Questions_Per_Page__c = 3,
                    Thank_You_Message__c = 'Thank you!'
                )
            );
        }
        if (doCommit) {
            lstSurveys = commitRecords(lstSurveys);
        }
        return lstSurveys;
    }


    /******************************
     * Survey Questions
     ******************************/

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
                    Question__c = SURVEY_QUESTION_BASE + ' ' + String.valueOf(i) + '?',
                    Help_Text__c = 'Some helpful info'
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
     * Users
     ******************************/

     /******************************
     * Get a test user
     * @param String userType - Valid values are 'Admin' and 'Reviewer'
     * @return User
     ******************************/
    public static User createUser(
        String userType
    ) {
        String profileName;
        String permSetName;
        if (userType == 'Admin') {
            profileName = 'System Administrator';
            permSetName = 'Surveys_Admin';
        } else if (userType == 'Reviewer') {
            profileName = 'Standard User';
            permSetName = 'Surveys_Reviewer';
        }

        UserRole uRole = new UserRole(DeveloperName = 'TestCustomRole', Name = 'Test Custom Role');
        insert uRole;
        
        Profile profile = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        User u = getDefaultUser(uRole.Id, profile.Id, 'Test', 'User');
        insert u;

        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = :permSetName LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = permSet.Id);

        return u;
    }

    private static User getDefaultUser(
        Id roleId, 
        Id profileId,
        String firstName,
        String lastName
    ) {
        String orgId      = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;

        User u = new User();
        u.IsActive          = true;
        u.TimeZoneSidKey    = UserInfo.getTimeZone().toString();
        u.LocaleSidKey      = UserInfo.getLocale();
        u.LanguageLocaleKey = UserInfo.getLocale();
        u.EmailEncodingKey  = 'ISO-8859-1';
        u.Username          = uniqueName + '@test' + orgId + '.org';
        u.Email             = uniqueName + '@test' + orgId + '.org';
        u.FirstName         = firstName;
        u.LastName          = lastName;
        u.Alias             = uniqueName.substring(18, 23);
        u.UserRoleId        = roleId;
        u.ProfileId         = profileId;
        return u;
    }


    /******************************
     * DML
     ******************************/
    private static List<SObject> commitRecords(List<SObject> lstObjects) {
        Database.upsert(lstObjects, AccessLevel.SYSTEM_MODE);
        return lstObjects;
    }

}