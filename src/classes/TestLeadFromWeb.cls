@isTest
private class TestLeadFromWeb 
{
    static testMethod void TestLeadWithNoLeadSource() 
    {
    	Lead testLead = new Lead (Salutation='Mr.', FirstName = 'Test', LastName = 'Testing123', Company = 'Self', EMail = 'test@test123.com', Status='Open - not converted', MobilePhone='08654323');
    	insert testLead;
    	testLead = [select ID, Conversion_Error__c from Lead where ID=:testLead.id];
    	system.assertEquals ('LeadSource field not populated', testLead.Conversion_Error__c);
    }

    static testMethod void TestLeadWithWrongLeadSource() 
    {
    	Lead testLead = new Lead (Salutation='Mr.', FirstName = 'Test', LastName = 'Testing123', Company = 'Self', EMail = 'test@test123.com', Status='Open - not converted', MobilePhone='08654323', LeadSource='x');
    	insert testLead;
    	testLead = [select ID, Conversion_Error__c from Lead where ID=:testLead.id];
    	system.assert (testLead.Conversion_Error__c.contains ('not matching'));
    }

    static testMethod void TestLeadWithNoContactsPresent() 
    {
    	Lead testLead = new Lead (Salutation='Mr.', FirstName = 'Test', LastName = 'Testing123', Company = 'Self', EMail = 'test@test123.com', Status='Open - not converted', MobilePhone='08654323', LeadSource='Projects');
    	insert testLead;
    	Contact newContact = [select FirstName from Contact where LastName = :testLead.LastName];
    	system.assertEquals (testLead.FirstName, newContact.FirstName);
    }
    
    static testMethod void TestLeadWithContactPresent() 
    {
    	Contact testContact = new Contact (Salutation='Mr.', FirstName = 'Test', LastName = 'Testing123', EMail = 'test@test123.com');
    	insert testContact;
    	Lead testLead = new Lead (Salutation='Mr.', FirstName = 'Test', LastName = 'Testing123', Company = 'Self', EMail = 'test@test123.com', Status='Open - not converted', MobilePhone='08654323', LeadSource='Projects');
    	insert testLead;
    	list<Contact> newContacts = [select FirstName from Contact where LastName = :testLead.LastName];
    	system.assertEquals (1, newContacts.size());
    }
    
    static testMethod void TestLeadWithAmount() 
    {
    	Lead testLead = new Lead (Salutation='Mr.', FirstName = 'Test', LastName = 'Testing123', Company = 'Self', EMail = 'test@test123.com', Status='Open - not converted', MobilePhone='08654323', LeadSource='Projects');
    	testLead.Total_donation__c = 40;
    	testLead.Description = '[{"Description":"Mosquito nets","quantity":"1.00","Amount":"10.00"},{"Description":"Chickens","quantity":"2.00","Amount":"30"}]';
    	testLead.HasOptedOutOfEmail = true;
    	testLead.Donating_on_behalf_of_an_organisation__c = false;
    	insert testLead;
    	Opportunity newDonation = [select Amount from Opportunity];
    	system.assertEquals (testLead.Total_donation__c, newDonation.Amount);
    }
    
    static testMethod void TestLeadWithRelatedOrg() 
    {
    	Lead testLead = new Lead (Salutation='Mr.', FirstName = 'Test', LastName = 'Testing123', Company = 'Self', EMail = 'test@test123.com', Status='Open - not converted', MobilePhone='08654323', LeadSource='Projects');
    	testLead.Total_donation__c = 40;
    	testLead.Description = '[{"Description":"Mosquito nets","quantity":"1.00","Amount":"10.00"},{"Description":"Chickens","quantity":"2.00","Amount":"30"}]';
    	testLead.HasOptedOutOfEmail = true;
    	testLead.Donating_on_behalf_of_an_organisation__c = true;
    	testLead.Related_Organisation__c = 'Test Org';
    	testLead.Comment__c = 'Some comment';
    	insert testLead;
    	Opportunity newDonation = [select Amount from Opportunity];
    	system.assertEquals (testLead.Total_donation__c, newDonation.Amount);
    }
    
}