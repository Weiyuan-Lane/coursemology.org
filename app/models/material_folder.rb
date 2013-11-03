class MaterialFolder < ActiveRecord::Base
  belongs_to :creator, class_name: "User"

  # Folder structure
  belongs_to :parent_folder, class_name: "MaterialFolder"
  belongs_to :course, class_name: "Course"
  has_many :subfolders, dependent: :destroy, class_name: "MaterialFolder", foreign_key: "parent_folder_id"
  has_many :files, dependent: :destroy, class_name: "Material", foreign_key: "folder_id"

  attr_accessible :parent_folder, :course, :course_id, :name, :description

  # Creates a virtual item of this class that is backed by some other data store.
  def self.create_virtual(id, parent_id)
    (Class.new do
      # Give the ID of this virtual folder. Should be the module name.
      def initialize(id, parent_id)
        @id = id
        @name = @description = nil
        @files = []
        @parent_folder = MaterialFolder.find_by_id(parent_id)
      end

      def id
        @id
      end
      def name
        @name
      end
      def name=(name)
        @name = name
      end
      def description
        @description
      end
      def description=(description)
        @description = description
      end
      def files
        @files
      end
      def files=(files)
        @files = files
      end
      
      # For now virtual folders can't have subfolders, so we merge them
      def materials
        files
      end
      def parent_folder
        @parent_folder
      end
      def parent_folder_id
        @parent_folder.id
      end
      def subfolders
        []
      end
      def updated_at
        nil
      end

      def is_virtual
        true
      end
    end).new(id, parent_id)
  end

  def materials
    result = []
    self.subfolders.each { |f| result += f.materials }
    self.files.each { |f| result += [f] }
    
    result
  end

  def attach_files(files, descriptions)
    files.each do |key, id|
      # Create a material record
      material = Material.create(folder: self)

      # Associate the file upload with the record
      file = FileUpload.find_by_id(id)
      if not(file)
        next
      end
      material.attach(file)
      material.description = descriptions[key]
      material.save
    end
  end

  def new_subfolder(name, description = nil)
    subfolder = MaterialFolder.create(:parent_folder => self, :course_id => course_id, :name => name, :description => description)
    subfolder.save
  end

  def is_virtual
    false
  end
end
