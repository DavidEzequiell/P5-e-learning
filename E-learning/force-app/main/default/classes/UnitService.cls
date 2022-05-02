public class UnitService {

    
    public static Boolean registerUnitResponse(Id unitId, String jsonAnswer){

        SavePoint sp = Database.setSavepoint();
        try{
            
       
        //Busco la unidad desde la base de datos.
        Unit__c unit = [SELECT Module__c,(SELECT Id, Numbers_of_Tries__C FROM Unit_Responses__r WHERE Module_Response__C.User__c =: Userinfo.getUserId() ORDER BY Numbers_of_Tries__C DESC LIMIT 1 ), (SELECT id, name FROM Questions__r) from Unit__c where Id =: unitId];
        
        //Verifico si existe un modulo
        Module_Response__c moduleResp = [SELECT Id from Module_Response__c WHERE Module__C =: Unit.Module__C AND User__c =: Userinfo.getUserId() AND Status__c =: 'In Progress'];
    
            if( moduleResp == null){
            //Creación e inserción de Module Response.
            moduleResp = new Module_Response__c (User__c= Userinfo.getUserId(), Module__c = unit.Module__C, Status__c = 'In Progress' );
            insert moduleResp;
        }

               //Creacion e insercion de unit response
               Unit_Response__c unitResp = new Unit_Response__c(Unit__c = unitId, Module_Response__c = moduleResp.Id, unit_Status__c = 'Draft');
               //NTH!
               unitResp.Numbers_of_tries__c = !unit.Unit_Responses__r.isEmpty() ? unit.Unit_Responses__r[0].Numbers_Of_Tries__c + 1 : 1;
               insert unitResp;

               
        //Creo y cargo question responses
        Map<Id,Id> answerMap = (Map<Id,Id>)JSON.deserializeStrict(jsonAnswer, Map<Id,Id>.class);
        List<Question_Response__c> questionRespList = new List<Question_Response__c>();
        for(Question__c question : unit.Questions__r){
            //Verifico si la pregunta fue respondida en el mapa
            if(answerMap.containsKey(question.Id)){
                Question_Response__c questionResp = new Question_Response__c(Question__c = question.Id, Unit_Response__c = unitResp.Id, Answer__c = answerMap.get(question.Id));
                questionRespList.add(questionResp);
            }else{
                throw new Exception('La pregunta ' + question.Name + ' no fue respondida y es requerida.');
            }
        }
        insert questionRespList;
        unitResp.unit_Status__c = 'Answered';
        update unitResp;
        return true;
    }catch(Exception e){
        Database.rollback(sp);
        return false;
        throw e;
    }
   }
}