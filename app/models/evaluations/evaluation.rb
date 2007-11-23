
require 'fastercsv'

# An Evaluation gives an overview of the worktimes reported to the system.
# It provides the sum of all Worktimes for a category, split up into several divisions.
# The detailed Worktimes may be inspected for the whole category or a certain division only.
# The worktime information may be constrained to certain periods of time.
#
# This class is abstract, subclasses generally override the class constants for customization.
class Evaluation 

  # The method to send to the category object to retrieve a list of divisions.
  DIVISION_METHOD  = :list  
           
  # Next lower evaluation for divisions, which will be acting as the category there.
  SUB_EVALUATION   = nil    
      
  # Name of the evaluation to be displayed     
  LABEL            = ''              
  
  # Whether this Evaluation is for absences or project times.
  ABSENCES         = false   
  
  # Whether details for totals are possible.  
  TOTAL_DETAILS    = true    
  
  # Wheter this Evaluation displays attendance times for its category in the overview.
  ATTENDANCE       = false
  
  # The field of a division referencing the category entry in the database. 
  # May be nil if not required for this Evaluation (default).
  CATEGORY_REF     = nil          
  
  # Columns to display in the detail view
  DETAIL_COLUMNS   = [:work_date, :hours, :employee, :account, :billable, :description]
  
  # Table captions for detail columns
  DETAIL_LABELS    = {:work_date   => 'Datum',
                      :hours       => 'Stunden',
                      :times       => 'Zeiten',
                      :employee    => 'Wer',
                      :account     => 'Projekt',
                      :billable    => '$',
                      :description => 'Beschreibung'}
  
  
  attr_reader :category,             # category              
              :division              # selected division for detail Evaluations, nil otherwise
  
  
  ############### Time Evaluation Functions ###############
  
  # Returns a list of all division objects for the represented category.
  def divisions  
    category.send(self.class::DIVISION_METHOD)
  end
  
  # The record identifier of the category, 0 if category is not an active record
  def category_id
  	category.is_a?(Class) ? 0 : category.id
  end
 
  # Sums all worktimes for a given period.
  # If a division is passed or set previously, their sum will be returned.
  # Otherwise the sum of all worktimes in the main category is returned.
  def sum_times(period, div = nil, options = {})
    div ||= division
    sendTimeQuery(:sumWorktime, period, div, options)
  end  

  # Sums all worktimes for the category in a given period.
  def sum_total_times(period = nil, options = {})
    category.sumWorktime(self, period, false, options)
  end
    
  # Counts the number of Worktime entries in the current Evaluation for a given period.
  def count_times(period)
    sendTimeQuery(:countWorktimes, period, division)
  end
  
  # Returns a list of all Worktime entries for this Evaluation in the given period
  # of time.
  def times(period, options = {})
    sendTimeQuery(:findWorktimes, period, division, options)
  end
  
  # Field with category reference for divisions. Nil if not required.
  # Returns the configured class constant.
  def categoryRef
    self.class::CATEGORY_REF
  end
          
  # Whether this Evaluation is for Absences or Projects. 
  # Returns the configured class constant. 
  def absences?
    self.class::ABSENCES
  end   
        
  ################ Methods for overview ##############
  
  # The label to be displayed for this Evaluation. Returns the configured class constant.
  def label
    self.class::LABEL
  end
  
  # The title for this Evaluation
  def title
    label + (class_category? ? ' &Uuml;bersicht' : ' von ' + category.label)
  end
  
  # The header name of the division column to be displayed.
  # Returns the class name of the division objects.
  def division_header
    divs = divisions
    divs.first ? divs.first.class.label : ''
  end
 
  # Returns a two-dimensional Array with helper methods of the evaluator
  # to be called in the overview (_division.rhtml) for each division 
  # and the according table headers. May be used for displaying additional 
  # information or links to certain actions.
  # No methods are called by default.
  # See EmployeeProjectsEval for an example.
  def division_supplement(user)
    []
  end
    
  # Returns whether this Evaluation is personally for the current user. 
  # Default is false.  
  def for?(user)
    false
  end 
  
  def ==(other)
    self.class == other.class &&
      self.category == other.category
  end
  
  ################ Methods for detail view ##############
  
  # Sets the id of the division object used for the detailed view.
  # Default is nil, the worktimes of all divisions are provided.
  def set_division_id(division_id = nil)
    return if division_id.nil?
    container = class_category? ? category : divisions
    @division = container.find(division_id.to_i)
  end
  
  # Label for the represented category.
  def category_label
    detail_label(category)
  end  
  
  # Label for the represented division, if any.
  def division_label
    detail_label(division)
  end
    
  def editLink?(user)
    for?(user) || ! absences?
  end
  
  def deleteLink?(user)
    for? user
  end
  
  def splitLink?(user)
    false
  end
  
  # Returns a CSV String for all times in this Evaluation
  def csvString(period)
    FasterCSV.generate do |csv|
      csv << ["Datum", "Stunden", "Von Zeit", "Bis Zeit", "Reporttyp",
              "Verrechenbar", "Mitarbeiter", "Projekt", "Beschreibung"]
      times(period).each do |time|
        csv << [ time.work_date.strftime(DATE_FORMAT),
                 time.hours,
                 (time.startStop? ? time.from_start_time.strftime("%H:%M") : ''),
                 (time.startStop? ? time.to_end_time.strftime("%H:%M") : ''),
                 time.report_type,
                 time.billable,
                 time.employee.label,
                 (time.account ? time.account.label : 'Anwesenheitszeit'),
                 time.description ]
      end
    end 
  end
      
protected

  # Initializes a new Evaluation with the given category.
  def initialize(category)
    @category = category
  end
  
private
       
  def detail_label(item)
    return '' if item.nil? || item.kind_of?(Class)
    item.class.label + ': ' + item.label
  end   
  
  def class_category?
    category.kind_of? Class
  end
    
  def sendTimeQuery(method, period = nil, div = nil, options = {})
    receiver = div ? div : category
    receiver.send(method, self, period, div && categoryRef, options)
  end
  
end 