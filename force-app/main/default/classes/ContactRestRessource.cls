/**
 *    Cette classe Apex définit des services REST pour la manipulation des objets Contact dans Salesforce.
 *    Elle prend en charge les opérations de mise à jour en vrac des champs et de désactivation des contacts.
 *    REMARQUE: Les champs ExternalId__c et IsActive__c champs customs qui doivent avoir été créés au préalable.

 *    @author Carine Flood
 *    @version 1.0
 *    @since 2023-11-14
 */

@RestResource(urlMapping='/Contact/*')
global with sharing class ContactRestRessource {
    /**
    * Met à jour en masse les champs des contacts, ou crée de nouveaux contacts (upsert) en fonction des données fournies.
    * 
    Exemple d'utilisation:
    *    - Mise à jour ou création (upsert) en vrac de contacts:
    *      Endpoint: /services/apexrest/Contact/
    *      Méthode: PUT
    *      Expemple de corps de la requête:
    *      {
    *        "records": [
    *          {
    *            "ExternalId__c": "externalId fourni par AGX",
    *            "FirstName": "NouveauPrénom",
    *            "LastName": "NouveauNom"
    *          }, {
    *            "ExternalId": ""externalId fourni par AGX"",
    *            "Email": "nouveau@email.com"
    *          }]
    *      }
    *  @return Liste des informations des contacts mis à jour.
    */

    @HttpPut
    global static List<Map<String, String>> updateContactFields() {
        //récupère la demande (request) HTTP entrante
        RestRequest request = RestContext.request;
        
        // désérialise le corps de la demande JSON en utilisant la méthode JSON.deserializeUntyped pour obtenir les paires nom-valeur.
        Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
        List<Object> enregistrements =(List<Object>) params.get('records');
        
        // Crée une liste de contacts à mettre à jour en dehors de la boucle
        List<Contact> contactsToUpdate = new List<Contact>();
        
        for (Object enr : enregistrements){
            Map<String, Object> attributDesenregistrements = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(enr));
            Contact contact= new Contact(); 
            // itère à travers chaque champ et sa valeur dans les données JSON
            for (String fieldName : attributDesenregistrements.keySet()) {
                // met à jour les champs du contact en utilisant les valeurs fournies dans les données JSON
                contact.put(fieldName, attributDesenregistrements.get(fieldName));
            }
            // Ajoute le contact à la liste des contacts à mettre à jour
            contactsToUpdate.add(contact);   
        }
        // Met à jour ou crée les contacts dans Salesforce
        upsert contactsToUpdate Contact.ExternalId__c;

        // Crée une liste pour stocker les informations qui seront retournés à Postman
        List<Map<String, String>> updatedContactsInfo = new List<Map<String, String>>();

        // Récupère les informations d'Id et ExternalId__c des contacts mis à jour
        for (Contact updatedContact : contactsToUpdate) {
            Map<String, String> contactInfo = new Map<String, String>();
            contactInfo.put('Id', updatedContact.Id);
            contactInfo.put('ExternalId__c', updatedContact.ExternalId__c);
            updatedContactsInfo.add(contactInfo);
        }
        return updatedContactsInfo;
    }
    /**
    * Désactive en masse les contacts en fonction des données fournies.
    * 
    *      Endpoint: /services/apexrest/Contact/
    *      Méthode: DELETE
    *      Corps de la requête:
    *      {
    *        "records": [
    *          {
    *            "ExternalId__c": "externalId fourni par AGX"
    *          },{
    *            "ExternalId__c": "externalId fourni par AGX"
    *          }]
    *      }
    */
 
    @HttpDelete 
    global static void deletedContactWillBeDeactivated() {
        //récupère la demande (request) HTTP entrante
        RestRequest request = RestContext.request;

        // désérialise le corps de la demande JSON en utilisant la méthode JSON.deserializeUntyped pour obtenir les paires nom-valeur.
        Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
        List<Object> enregistrements =(List<Object>) params.get('records');

        // Crée une liste pour contenir les ExternalId récupérés dans une itération sur les enregistrements 
        List <String> externalIdsList = new List <String> ();
        for (Object enr : enregistrements){
            Map<String, Object> attributDesenregistrements = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(enr));
            externalIdsList.add((String)attributDesenregistrements.get('ExternalId__c'));
        }
        //Recherche les contacts dont l'ExternalId est présent dans ExternalIdsList, désactive leur champ IsActive et les stocke dans une liste à mettre à jour
        List<Contact> contactsToDelete = [SELECT Id FROM Contact WHERE ExternalId__c IN: externalIdsList];
        for (Contact con : contactsToDelete ){
            con.IsActive__c = false;
        }
        update contactsToDelete;
    }     
}