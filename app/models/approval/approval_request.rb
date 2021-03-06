class Approval::ApprovalRequest < ActiveRecord::Base
  include Sys::Model::Base

  belongs_to :requester, :foreign_key => :user_id, :class_name => 'Sys::User'
  validates_presence_of :user_id
  belongs_to :approvable, :polymorphic => true
  validates_presence_of :approvable_type, :approvable_id
  belongs_to :approval_flow
  validates_presence_of :approval_flow_id

  has_many :current_assignments, :class_name => 'Approval::Assignment', :as => :assignable, :dependent => :destroy
  has_many :current_approvers, :through => :current_assignments, :source => :user
  has_many :histories, :foreign_key => :request_id, :class_name => 'Approval::ApprovalRequestHistory', :dependent => :destroy,
           :order => 'updated_at DESC, created_at DESC'

  after_initialize :set_defaults

  def current_approval
    approval_flow.approvals.find_by_index(current_index)
  end

  def min_index
    0
  end

  def max_index
    approval_flow.approvals.map(&:index).max
  end

  def approve(user)
    return false unless current_approvers.include?(user)

    transaction do
      histories.create(operator: user, reason: 'approve', comment: '')
      current_assignments.find_by_user_id(user.id).update_attribute(:approved_at, Time.now)
      current_assignments.reload # flush cache
    end

    if current_assignments.all?{|a| a.approved_at }
      if current_index == max_index
        yield('finish') if block_given?
      else
        transaction do
          increment!(:current_index)
          current_assignments.destroy_all
          current_approver_ids = current_approval.approver_ids
          reload # flush cache
        end
        yield('progress') if block_given?
      end
    end

    return true
  end

  def passback(approver, comment: '')
    return false unless current_approvers.include?(approver)

    transaction do
      histories.create(operator: approver, reason: 'passback', comment: comment || '')
      reset
    end

    return true
  end

  def pullback(comment: '')
    transaction do
      histories.create(operator: self.requester, reason: 'pullback', comment: comment || '')
      reset
    end

    return true
  end

  def finished?
    current_index == max_index && current_assignments.all?{|a| a.approved_at }
  end

  def reset
    transaction do
      update_column(:current_index, min_index)
      current_assignments.destroy_all
      current_approver_ids = current_approval.approver_ids
      reload # flush cache
    end
  end

  private

  def set_defaults
    self.current_index = min_index if has_attribute?(:current_index) && current_index.nil?
    self.current_approver_ids = current_approval.approver_ids if current_approvers.empty?
  end
end
