@isTest
private class TestRecordsGeneratorTest {
   /**
    * Test to make sure the TestRecordsGenerator fulfills the requirements for
    * the coding challenge
    */
    @isTest
    static void testFulfillRequirements() {
        generateTestUsers();

        Test.startTest();
        TestRecordsGenerator.generate();
        Test.stopTest();

        User[] testUsers = [SELECT Id FROM User
                            WHERE Is_Test_User__c = TRUE];

        Lead[] testLeads = [SELECT Id FROM Lead
                            WHERE Is_Test_Lead__c = TRUE];

        Opportunity[] testOpps = [SELECT Id FROM Opportunity
                                  WHERE Is_Test_Opp__c = TRUE];

        // At least 5 different Users to be displayed
        System.assert(testUsers.size() >= 5);
        // At least 100 test Lead records
        System.assert(testLeads.size() >= 100);
        // At least 20 test Opp records
        System.assert(testOpps.size() >= 20);
    }

   /**
    * Test to make sure that running the generator multiple times will clean up
    * old test records first before generating enough test records to fulfill
    * the requirements for the coding challenge
    */
    @isTest
    static void testResetsCorrectly() {
        generateTestUsers();

        Test.startTest();
        TestRecordsGenerator.generate();
        TestRecordsGenerator.generate();
        TestRecordsGenerator.generate();
        Test.stopTest();

        User[] testUsers = [SELECT Id FROM User
                            WHERE Is_Test_User__c = TRUE];

        Lead[] testLeads = [SELECT Id FROM Lead
                            WHERE Is_Test_Lead__c = TRUE];

        Opportunity[] testOpps = [SELECT Id FROM Opportunity
                                  WHERE Is_Test_Opp__c = TRUE];

        // Less than 150 test Lead records
        System.assert(testLeads.size() < 150);
        // Less than 30 test Opp records
        System.assert(testOpps.size() < 30);

        // Still fulfills requirements for the coding challenge

        // At least 5 different Users to be displayed
        System.assert(testUsers.size() >= 5);
        // At least 100 test Lead records
        System.assert(testLeads.size() >= 100);
        // At least 20 test Opp records
        System.assert(testOpps.size() >= 20);
    }

   /**
    * Test setup static method to generate the test Users needed for
    * TestRecordsGenerator to work properly
    */
    static void generateTestUsers() {
        User[] testUsers = new User[] {};
        User testUser;
        String username;

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];

        for (Integer i = 0; i <= 5; i++) {
            username = 'test' + i + '@user.invalid';

            testUser = new User(
                Username=username,
                Email=username,
                Alias='test' + i,
                TimeZoneSidKey='America/New_York',
                LocaleSidKey='en_US',
                EmailEncodingKey='ISO-8859-1',
                ProfileId=p.Id,
                LanguageLocaleKey='en_US',

                Is_Test_User__c=true
            );

            // Special test User
            if (i == 0) {
                testUser.LastName = 'Solis';
            } else {
                testUser.LastName = 'User ' + i;
            }

            testUsers.add(testUser);
        }

        insert testUsers;
    }
}
