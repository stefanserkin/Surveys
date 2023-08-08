import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import initializeSurvey from '@salesforce/apex/CommunitySurveyController.initializeSurvey';
import submitSurvey from '@salesforce/apex/CommunitySurveyController.submitSurvey';

import SURVEY_ANSWER_OBJECT from '@salesforce/schema/Survey_Answer__c';
import ANSWER_QUESTION_FIELD from '@salesforce/schema/Survey_Answer__c.Question__c';
import ANSWER_ANSWER_FIELD from '@salesforce/schema/Survey_Answer__c.Answer__c';
import ANSWER_SURVEY_QUESTION_FIELD from '@salesforce/schema/Survey_Answer__c.Survey_Question__c';
import ANSWER_DATA_TYPE_FIELD from '@salesforce/schema/Survey_Answer__c.Data_Type__c';
import SURVEY_NAME_FIELD from '@salesforce/schema/Survey__c.Name';
import SURVEY_PAGINATED_FIELD from '@salesforce/schema/Survey__c.Paginated__c';
import SURVEY_MAX_QUESTIONS_FIELD from '@salesforce/schema/Survey__c.Max_Questions_Per_Page__c';
import SURVEY_TY_MESSAGE_FIELD from '@salesforce/schema/Survey__c.Thank_You_Message__c';

export default class CommunitySurvey extends NavigationMixin(LightningElement) {
    @api recordId;
    currentPageReference;
    error;
    isLoading = false;
    isSubmitted = false;

    /*********************************
     * Survey question data
     *********************************/
    survey;
    wiredQuestions = [];
    questions;

    /*********************************
     * Object fields
     *********************************/
    fields = {
        answerQuestion: ANSWER_QUESTION_FIELD,
        answerAnswer: ANSWER_ANSWER_FIELD,
        answerSurveyQuestion: ANSWER_SURVEY_QUESTION_FIELD,
        answerDataType: ANSWER_DATA_TYPE_FIELD,
        surveyName: SURVEY_NAME_FIELD,
        surveyPaginated: SURVEY_PAGINATED_FIELD,
        surveyMaxQuestions: SURVEY_MAX_QUESTIONS_FIELD,
        thankYouMessage: SURVEY_TY_MESSAGE_FIELD
    };

    /*********************************
     * Form display settings
     *********************************/
    isPaginated = false;
    maxQuestionsPerPage = 5;
    currentPage = 1;
    currentPageQuestions;

    get totalPages() {
        let result = 0;
        if (this.questions && this.questions.length > 0 && this.maxQuestionsPerPage) {
            result = Math.ceil(this.questions.length / this.maxQuestionsPerPage);
        }
        return result;
    }

    get isMultiplePages() {
        return this.totalPages && this.totalPages.length > 1;
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
        fields : [SURVEY_NAME_FIELD, SURVEY_PAGINATED_FIELD, SURVEY_MAX_QUESTIONS_FIELD, SURVEY_TY_MESSAGE_FIELD]
    }) wireSurvey({
        error,
        data
    }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.survey = data;
            this.isPaginated = data.fields[this.fields.surveyPaginated.fieldApiName].value;
            this.maxQuestionsPerPage = data.fields[this.fields.surveyMaxQuestions.fieldApiName].value;
        }
    }

    get surveyTitle() {
        return this.survey 
            ? this.survey.fields[this.fields.surveyName.fieldApiName].value 
            : 'Survey';
    }

    get thankYouMessage() {
        return this.survey && this.survey.fields[this.fields.thankYouMessage.fieldApiName] != null
            ? this.survey.fields[this.fields.thankYouMessage.fieldApiName].value
            : 'Thank you!'
    }

    /**
     * Get collection of question records
     * @param {*} recordId - Survey record id from flexipage
     */
    @wire(initializeSurvey, {recordId: '$recordId'})
    wiredResult(result) {
        this.isLoading = true;
        this.wiredQuestions = result;
        if (result.data) {
            let rows = JSON.parse( JSON.stringify(result.data) );

            let i = 0;
            rows.forEach(q => {
                q.answer = this.getInitialFieldValue(i);
                i++;
            });

            this.questions = rows;
            this.updateCurrentPageQuestions();
            this.error = undefined;
            this.isLoading = false;
        } else if (result.error) {
            console.error(result.error);
            this.questions = undefined;
            this.error = result.error;
            this.isLoading = false;
        }
    }

    /*********************************
     * Handle input
     *********************************/

    handleInputChange(event) {
        const questionId = event.target.dataset.qid;
        const updatedQuestions = this.questions.map((q) => {
            if (q.id === questionId) {
                return { ...q, answer: String( event.target.value ) };
            }
            return q;
        });
        this.questions = updatedQuestions;
    }

    /**
     * Submit survey
     * Validate input
     * Create survey response and survey answers
     */
    handleSubmitSurvey() {
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputFields) => {
                inputFields.reportValidity();
                return validSoFar && inputFields.checkValidity();
            }, true);

        if (allValid) {
            const records = this.questions.map((q) => {
                let answer = {};
                answer.sobjectType = SURVEY_ANSWER_OBJECT.objectApiName;
                answer[this.fields.answerSurveyQuestion.fieldApiName] = q.id;
                answer[this.fields.answerQuestion.fieldApiName] = q.question;
                answer[this.fields.answerAnswer.fieldApiName] = String( q.answer );
                answer[this.fields.answerDataType.fieldApiName] = q.dataType;
                return answer;
            });
            
            submitSurvey({ 
                recordId: this.recordId, 
                contactId: this.contactId, 
                answers: records
            }).then((result) => {
                this.isSubmitted = true;
                const event = new ShowToastEvent({
                    title: 'Thank you!',
                    message: 'Your response has been recorded',
                    variant: 'success'
                });
                this.dispatchEvent(event);
            }).catch((error) => {
                this.error = error;
                console.error(this.error);
                const event = new ShowToastEvent({
                    title: 'Your response could not be recorded',
                    message: this.getErrorMessage(),
                    variant: 'error'
                });
                this.dispatchEvent(event);
            });
        } else {
            console.log('Input is not valid');
        }

    }

    getErrorMessage() {
        let message = 'Unknown error';
        if (Array.isArray(this.error.body)) {
            message = this.error.body.map(e => e.message).join(', ');
        } else if (typeof this.error.body.message === 'string') {
            message = this.error.body.message;
        }
        return message;
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
        this.currentPageQuestions = this.questions.slice(startIndex, endIndex);
    }

    get disablePreviousButton() {
        return this.currentPage === 1;
    }

    get disableNextButton() {
        return this.currentPage === this.totalPages;
    }

}