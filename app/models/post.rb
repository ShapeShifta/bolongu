class Post < ActiveRecord::Base  
  
  belongs_to :author, :class_name => 'Account'
  has_many :comments, :as => :commentable, :dependent => :destroy
  has_many :commentators, :class_name => 'Account', :source => :author ,:through => :comments, :uniq => true
  
  has_attached_file :photo, :styles => { :default => ["640x480>", :jpg], :small => ["320x240>", :jpg], :tiny => ["160x120>", :jpg] }
  
  validates_attachment_content_type :photo, :content_type => [ 'image/jpeg', 'image/png', 'image/bmp' , 'image/gif' ]
  validates_attachment_size :photo, :less_than => 5.megabytes
  
  default_scope :order => 'created_at DESC'
  
  alias :account :author
  
end
