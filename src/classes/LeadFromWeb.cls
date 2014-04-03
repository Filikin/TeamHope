public with sharing class LeadFromWeb implements TriggerDispatcher.ITriggerEntry
{
	public void MainEntry (String TriggerObject, Boolean isBefore, Boolean isDelete, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isExecuting,
		List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap)
	{
		if (isBefore)
		{
			LeadInsertedOrUpdated (newList);
		}
	}

	void LeadInsertedOrUpdated (List<Lead>newLeads)
	{
 		String actualFieldSetName;
 		Id donationRecordTypeID = [select ID from RecordType where sObjectType='Opportunity' and DeveloperName='Donation' limit 1].id;
    	for(Lead ld: newLeads)
    	{
	    	if (ld.leadsource == null) 
	    	{
	    		ld.Conversion_Error__c = 'LeadSource field not populated'; 
	    		continue; // not one of my web to leads
	    	}
	    	else actualFieldSetName = ld.leadsource;
	    	
	    	if (isValid(ld.Email) && isValid(actualFieldSetName) && isValid(ld.LastName) && ld.Status.contains('Open'))
	    	{
	    		Opportunity donation=null;
				if (ld.leadsource != 'CSAOrder' && isValidDecimal (ld.Total_donation__c)) donation = new Opportunity (CloseDate=system.today(), StageName='Pledged', Amount=ld.Total_donation__c, RecordTypeID=donationRecordTypeID);
	
	    		List<Schema.FieldSetMember> leadFields = null;
	    		List<Schema.FieldSetMember> contactFields = null;
	    		try
	    		{
			    	leadFields = getFields (actualFieldSetName.replace(' ','_'), true);
	    			contactFields = getFields (actualFieldSetName.replace(' ','_'), false);
	    		}
	    		catch (Exception e)
	    		{
	    			ld.Conversion_Error__c = 'Lead source "' + ld.leadsource + '" not matching a fieldset';
	    			continue;
	    		}
				
				Account contactsAccount=null;
	   			if (isValid(ld.Company))
	   			{
	   				try
	   				{
	   					contactsAccount = [select id, Name from Account where Name = :ld.Company limit 1];
	   				}
	   				catch (Exception e)
	   				{ // assume account not found
	   					contactsAccount = new Account (Name=ld.Company);
	   					insert contactsAccount;
	   				} 
	   			}
	
	   			Contact currentContact = null;
	   			Boolean newContact;
	 
	    		List<Contact> possibleContacts = [select id, FirstName, LastName, Related_Organisation__c from Contact where email = :ld.Email and LastName = :ld.LastName];
	    		if (possibleContacts.size() == 0)
	    		{
		    		currentContact = new Contact (LastName = ld.LastName, Email = ld.Email);
		    		newContact = true;
		    		if (contactsAccount != null)
		    		{
		    			if (ld.Donating_on_behalf_of_an_organisation__c) currentContact.AccountId = contactsAccount.id;
		    			else currentContact.Related_Organisation__c = contactsAccount.id;
		    		}
	    		}
	    		else
	    		{
	    			currentContact = possibleContacts[0];
	    			newContact = false;
		    		if (contactsAccount != null)
		    		{
		    			if (!ld.Donating_on_behalf_of_an_organisation__c) currentContact.Related_Organisation__c = contactsAccount.id;
		    		}
	   			}
		    	
		    	for (Integer i=0; i<leadFields.size(); i++)
		    	{
		    		try
		    		{
			    		String fieldName = leadFields[i].getFieldPath();
						Schema.DisplayType fieldType = leadFields[i].getType();
		    			if (fieldType == DisplayType.Date && isValidDate((Date)(ld.get(fieldName))) && newContact)
		    			{
		    				String contactFieldName = contactFields[i].getFieldPath().replace('ConvertedContact.','');
		    				currentContact.put(contactFieldName, (Date)(ld.get(fieldName)));
		    			}
				    	else if ((fieldType == DisplayType.Double || fieldType == DisplayType.Currency) && isValidDecimal((Decimal)(ld.get(fieldName))))
				    	{
		    				if (contactFields[i].getFieldPath().contains('ConvertedContact.') && newContact)
		    				{
			    				String contactFieldName = contactFields[i].getFieldPath().replace('ConvertedContact.','');
			    				currentContact.put(contactFieldName, (Decimal)(ld.get(fieldName)));
		    				}
		    				else if (contactFields[i].getFieldPath().contains('ConvertedOpportunity.') && donation != null)
		    				{
			    				String contactFieldName = contactFields[i].getFieldPath().replace('ConvertedOpportunity.','');
			    				donation.put(contactFieldName, (Decimal)(ld.get(fieldName)));
		    				}
				    	}
				    	else if (fieldType == DisplayType.Boolean)
				    	{
		    				Schema.DisplayType destFieldType = contactFields[i].getType();
		    				if (contactFields[i].getFieldPath().contains('ConvertedContact.') && newContact)
		    				{
			    				String contactFieldName = contactFields[i].getFieldPath().replace('ConvertedContact.','');
			    				if (destFieldType == DisplayType.Boolean) currentContact.put(contactFieldName, (Boolean)(ld.get(fieldName)));
			    				else currentContact.put(contactFieldName, (Boolean)(ld.get(fieldName))?1:0);
		    				}
		    				else if (contactFields[i].getFieldPath().contains('ConvertedAccount.') && contactsAccount != null)
		    				{
			    				String contactFieldName = contactFields[i].getFieldPath().replace('ConvertedAccount.','');
			    				if (destFieldType == DisplayType.Boolean) contactsAccount.put(contactFieldName, (Boolean)(ld.get(fieldName)));
			    				else contactsAccount.put(contactFieldName, (Boolean)(ld.get(fieldName))?1:0);
		    				}
		    				else if (contactFields[i].getFieldPath().contains('ConvertedOpportunity.') && donation != null)
		    				{
			    				String contactFieldName = contactFields[i].getFieldPath().replace('ConvertedOpportunity.','');
			    				if (destFieldType == DisplayType.Boolean) donation.put(contactFieldName, (Boolean)(ld.get(fieldName)));
			    				else donation.put(contactFieldName, (Boolean)(ld.get(fieldName))?1:0);
		    				}
				    	}
		    			else if (isValid((String)(ld.get(fieldName)))) 
		    			{
		    				if (contactFields[i].getFieldPath().contains('ConvertedContact.') && newContact)
		    				{
			    				String contactFieldName = contactFields[i].getFieldPath().replace('ConvertedContact.','');
						    	currentContact.put(contactFieldName, (String)(ld.get(fieldName)));
				    		}
				    		else if (contactFields[i].getFieldPath().contains('ConvertedAccount.') && contactsAccount != null)
				    		{
					    		String contactFieldName = contactFields[i].getFieldPath().replace('ConvertedAccount.','');
					    		contactsAccount.put(contactFieldName, (String)(ld.get(fieldName)));
				    		}
				    		else if (contactFields[i].getFieldPath().contains('ConvertedOpportunity.') && donation != null)
				    		{
			    				String contactFieldName = contactFields[i].getFieldPath().replace('ConvertedOpportunity.','');
			    				donation.put(contactFieldName, (String)(ld.get(fieldName)));
		    				}
		    			}
		    		}
		     		catch (Exception e)
		    		{
		    			ld.Conversion_Error__c = e.getMessage();
		    			return;
		    		}
		    	}	    		
		   		upsert currentContact;
	 	  		if (contactsAccount != null) update contactsAccount;
		    		
		   		try
		   		{
		    		if (donation != null) 
		    		{
			    			
		    			if (contactsAccount == null || !ld.Donating_on_behalf_of_an_organisation__c) // individual donating
			    		{
				   			donation.Name = currentContact.FirstName + ' ' + currentContact.LastName + ' - Donation ' + system.today().format();
			    			donation.AccountId = [select AccountID from Contact where ID = :currentContact.id limit 1].AccountID; 
			    		}
			    		else
			    		{
				   			donation.Name = contactsAccount.Name + ' - Donation ' + system.today().format();
			    			donation.npe01__Contact_Id_for_Role__c = currentContact.id;
			    			donation.AccountId = contactsAccount.Id;
			    		}
		    			donation.Payment_Type__c = 'Website Via Realex';
		    			insert donation;
		    			if (ld.leadsource == 'Projects' || ld.leadsource == 'HopeBook')
		    			{
		    				if (!CreateDonationItems (ld, donation)) continue; // failed because of an error processing the line items
		    			}
			    	}
				    ld.Status = 'Closed - Converted';
				    if (ld.Conversion_Error__c == null || ld.Conversion_Error__c == '') ld.Conversion_Error__c = 'None';
		    	}
		    	catch (Exception e)
		    	{
		    		ld.Conversion_Error__c = e.GetMessage();
		    	}
	    	}
		    else if (ld.Status.contains('Open'))
		    {
		    	if (!isValid(ld.Email)) ld.Conversion_Error__c = 'Email address invalid ';
		    	if (!isValid(ld.LastName)) ld.Conversion_Error__c += ' Surname not valid';
	    	}
		}
    }
    
	public static boolean isValid (String text)
	{
		if (text <> null && text <> '' && text <> '[not provided]') return true;
		else return false;
	}
	
	public static boolean isValidDate (Date text)
	{
		if (text <> null) return true;
		else return false;
	}
	
	public static boolean isValidDecimal (Decimal text)
	{
		if (text <> null) return true;
		else return false;
	}
	
	public List<Schema.FieldSetMember> getFields(String fieldSetName, Boolean bLeadFields) 
    {
    	System.Debug ('Fieldset name is' + fieldSetName);
    	Schema.FieldSet fs1 = Schema.SObjectType.Lead.fieldSets.getMap().get(fieldSetName);
    	if (fs1 == null) fs1 = Schema.SObjectType.Lead.fieldSets.getMap().get('Web_Membership_Form');
    	List<Schema.FieldSetMember> allFields = fs1.getFields();
     	List<Schema.FieldSetMember> returnFields = new List<Schema.FieldSetMember>();
    	
    	Integer start = bLeadFields ? 0:1;
    	for (Integer i=start; i<allFields.size(); i+=2)
    	{
			returnFields.add (allFields[i]);    		
    	}
    	return returnFields;
    }
	
	public String FirstCharCap (String bitname)
	{
		return bitname.substring(0,1).toUpperCase() + bitname.substring(1);
	}
	
	public boolean CreateDonationItems (Lead ld, Opportunity donation)
	{
		Savepoint sp = Database.setSavepoint();
		try
		{
			list<Line_Item__c> items = new list<Line_Item__c>();
			
			for (Object oneItem: (List<Object>)JSON.deserializeUntyped(ld.Description))
			{
				Map<String, Object> workingItem = (Map<String, Object>)oneItem;
				Line_Item__c newItem = new Line_Item__c (Donation__c=donation.id);
				newItem.Amount__c = Decimal.valueOf ((String)workingItem.get('Amount'));
				newItem.Quantity__c = Decimal.valueOf((String)workingItem.get('quantity'));
				newItem.Product__c = (String)workingItem.get('Description');
				items.add (newItem);
			}
			insert items;
			return true;
		}
		catch (Exception e)
		{
			Database.rollback(sp);
			ld.Conversion_Error__c += 'Problem with donation items list: ';
			ld.Conversion_Error__c += e.getMessage().left(1000);
		}
		return false;
	}

}