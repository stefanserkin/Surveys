import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import initializeSurvey from '@salesforce/apex/CommunitySurveyController.initializeSurvey';
import submitSurvey from '@salesforce/apex/CommunitySurveyController.submitSurvey';

import SURVEY_OBJECT from '@salesforce/schema/Survey__c';
import SURVEY_PAGINATED_FIELD from '@salesforce/schema/Survey__c.Paginated__c';
import SURVEY_MAX_QUESTIONS_FIELD from '@salesforce/schema/Survey__c.Max_Questions_Per_Page__c';
import SURVEY_QUESTION_OBJECT from '@salesforce/schema/Survey_Question__c';
import SURVEY_RESPONSE_OBJECT from '@salesforce/schema/Survey_Response__c';
import RESPONSE_SURVEY_FIELD from '@salesforce/schema/Survey_Response__c.Survey__c';
import RESPONSE_CONTACT_FIELD from '@salesforce/schema/Survey_Response__c.Contact__c';
import SURVEY_ANSWER_OBJECT from '@salesforce/schema/Survey_Answer__c';
import ANSWER_QUESTION_FIELD from '@salesforce/schema/Survey_Answer__c.Question__c';
import ANSWER_ANSWER_FIELD from '@salesforce/schema/Survey_Answer__c.Answer__c';
import ANSWER_SURVEY_QUESTION_FIELD from '@salesforce/schema/Survey_Answer__c.Survey_Question__c';
import ANSWER_SURVEY_RESPONSE_FIELD from '@salesforce/schema/Survey_Answer__c.Survey_Response__c';
import ANSWER_DATA_TYPE_FIELD from '@salesforce/schema/Survey_Answer__c.Data_Type__c';
import QUESTION_HELP_TEXT_FIELD from '@salesforce/schema/Survey_Answer__c.Help_Text__c';

export default class CommunitySurvey extends NavigationMixin(LightningElement) {
    @api recordId;
    currentPageReference;
    error;
    isLoading = false;

    /*********************************
     * Survey answer data
     *********************************/
    wiredAnswers = [];
    answers;

    /*********************************
     * Object fields
     *********************************/
    fields = {
        surveyPaginated: SURVEY_PAGINATED_FIELD, 
        surveyMaxQuestions: SURVEY_MAX_QUESTIONS_FIELD, 
        responseSurvey: RESPONSE_SURVEY_FIELD,
        responseContact: RESPONSE_CONTACT_FIELD,
        answerQuestion: ANSWER_QUESTION_FIELD,
        answerAnswer: ANSWER_ANSWER_FIELD, 
        answerSurveyQuestion: ANSWER_SURVEY_QUESTION_FIELD,
        answerSurveyResponse: ANSWER_SURVEY_RESPONSE_FIELD,
        answerDataType: ANSWER_DATA_TYPE_FIELD, 
        questionHelpText: QUESTION_HELP_TEXT_FIELD
    };

    /*********************************
     * Form display settings
     *********************************/
    isPaginated = false;
    maxQuestionsPerPage = 5;
    currentPage = 1;
    currentPageAnswers;

    get totalPages() {
        let result = 0;
        if (this.answers && this.answers.length > 0 && this.maxQuestionsPerPage) {
            result = Math.ceil(this.answers.length / this.maxQuestionsPerPage);
        }
        return result;
    }

    get noQuestionsMessage() {
        return this.recordId ? `There are no questions to display.` : '';
    }

    /**
     * Get current page reference from navigation service 
     * to access values passed in url parameters
     */
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
    }

    get contactId() {
        return this.currentPageReference?.state?.c__cId;
    }

    /**
     * Get preset values from url parameters by field index
     * @param {*} index 
     * @returns String - Preset field value
     */
    getInitialFieldValue(index) {
        let result = '';
        let fieldName = 'c__fv' + String(index);
        if (this.currentPageReference && this.currentPageReference.state) {
            let pageState = this.currentPageReference.state;
            if (Object.hasOwn(pageState, fieldName)) {
                result = pageState[fieldName];
            }
        }
        return result;
    }

    /**
     * Get survey details
     * @param recordId
     * @param fields
     */
    @wire(getRecord, { 
        recordId : '$recordId', 
        fields : [SURVEY_PAGINATED_FIELD, SURVEY_MAX_QUESTIONS_FIELD]
    }) wireSurvey({
        error,
        data
    }) {
        if (error) {
            this.error = error;
        } else if (data) {
            // this.isPaginated = data.fields[this.fields.surveyPaginated.fieldApiName].value;
            // this.maxQuestionsPerPage = data.fields[this.fields.surveyMaxQuestions.fieldApiName].value;
            // console.log(':::: isPaginated: ', this.isPaginated );
            // console.log(':::: isPaginated: ', this.maxQuestionsPerPage );
            console.log('data --> ', data);
        }
    }

    /**
     * Get collection of unsaved answered question records
     * @param {*} recordId - Survey record id from flexipage
     */
    @wire(initializeSurvey, {recordId: '$recordId'})
    wiredResult(result) {
        this.isLoading = true;
        this.wiredAnswers = result;
        if (result.data) {
            let rows = JSON.parse( JSON.stringify(result.data) );

            let i = 0;
            rows.forEach(ans => {
                ans.question = ans[this.fields.answerQuestion.fieldApiName];
                ans.answer = this.getInitialFieldValue(i);
                ans.dataType = this.setDataType(ans[this.fields.answerDataType.fieldApiName]);
                ans.helpText = ans[this.fields.questionHelpText.fieldApiName];
                i++;
            });

            this.answers = rows;
            this.updateCurrentPageQuestions();
            this.error = undefined;
            this.isLoading = false;
        } else if (result.error) {
            console.error(result.error);
            this.answers = undefined;
            this.error = result.error;
            this.isLoading = false;
        }
    }

    /**
     * Set data type for each answer. Maps picklist value to supported
     * value for lightning-input's 'type' attribute
     * @param obj answer 
     * @return void
     */

    setDataType(fieldDataType) {
        let dataType = 'Text';
        switch (fieldDataType) {
            case 'Text':
                dataType = 'text'
                break;
            case 'Number':
                dataType = 'number'
                break;
            case 'Date':
                dataType = 'date'
                break;
        }
        return dataType;
    }

    /*********************************
     * Handle input
     *********************************/

    handleInputChange(event) {
        const { name, value } = event.target;
        const answerId = name.substring(name.indexOf('_') + 1);
        const updatedAnswers = this.answers.map((answer) => {
            if (answer.Id === answerId) {
                return { ...answer, Answer__c: value };
            }
            return answer;
        });
        this.answers = updatedAnswers;
    }


    handleSubmitSurvey() {

        const records = this.answers.map((ans) => {
            let answer = {};
            answer[this.fields.answerSurveyQuestion.fieldApiName] = ans[this.fields.answerSurveyQuestion.fieldApiName];
            answer[this.fields.answerQuestion.fieldApiName] = ans.question;
            answer[this.fields.answerAnswer.fieldApiName] = ans.answer;
            answer[this.fields.answerDataType.fieldApiName] = ans[this.fields.answerDataType.fieldApiName];
            console.log(JSON.stringify(answer));
            
            return answer;
        });
        console.log(JSON.stringify(records));
        
        submitSurvey({ 
            recordId: this.recordId, 
            contactId: this.cId, 
            answers: records
        }).then(() => {
            const event = new ShowToastEvent({
                title: 'Success',
                message: 'Thank you for your submission, but it is lousy. We have thrown it in the trash.',
                variant: 'success'
            });
            this.dispatchEvent(event);
        }).catch((error) => {
            this.error = error;
            console.error(this.error);
            const event = new ShowToastEvent({
                title: 'Oh no. It has not done the thing',
                message: 'This did not go well.',
                variant: 'error'
            });
            this.dispatchEvent(event);
        });
    }

    /*********************************
     * Handle navigation
     *********************************/

    previousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updateCurrentPageQuestions();
        }
    }

    nextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updateCurrentPageQuestions();
        }
    }

    updateCurrentPageQuestions() {
        const startIndex = (this.currentPage - 1) * this.maxQuestionsPerPage;
        const endIndex = startIndex + this.maxQuestionsPerPage;
        this.currentPageAnswers = this.answers.slice(startIndex, endIndex);
    }

    get disablePreviousButton() {
        return this.currentPage === 1;
    }

    get disableNextButton() {
        return this.currentPage === this.totalPages;
    }

}