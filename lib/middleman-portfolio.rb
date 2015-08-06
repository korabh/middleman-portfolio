# Extension namespace
class Portfolio < ::Middleman::Extension
  TEMPLATES_DIR = File.expand_path('../template/source/', __FILE__)

  option :portfolio_dir, 'portfolio', 'Default portfolio directory inside your project'
  option :generate_thumbnails, true, 'Do you want thumbnails?'
  option :thumbnail_width, 200, "Width (in px) for thumbnails"
  option :thumbnail_height, 150,  "Height (in px) for thumbnails"

  attr_accessor :sitemap
  #alias :included :registered

  def initialize(app, options_hash={}, &block)
    # Call super to build options from the options_hash
    super

    # Require libraries only when activated
    # require 'necessary/library'

    # set up your extension
  end

  def after_configuration
    register_extension_templates
  end

  # create a resource for each portfolio project
  def project_resources    
    projects.collect {|project| project_resource(project)}
  end 

  def project_resource(project)
    source_file = template('project.html.erb')

    Middleman::Sitemap::Resource.new(app.sitemap, project_resource_path(project), source_file).tap do |resource|
      resource.add_metadata(options: { layout: false }, locals: {name: project})
    end
  end

  # get array of project thumbnail resources
  def project_resources    
    projects.collect {|project| project_resource(project)}
  end 

  def generate_thumbnail(image)
    img = ::MiniMagick::Image.open(image)
    img.resize "#{options.thumbnail_width}x#{options.thumbnail_height}"
    dst = File.join(Dir.tmpdir, thumbnail_name(image))
    img.write(dst)
    raise "Thumbnail not generated at #{dst}" unless File.exists?(dst)
    return dst
  end

  # generate thumbnail resource for each image in project dir
  def project_thumbnail_resources
    resources = Array.new
    
    for project in projects
      for image in project_images(project)
        debug "Generating thumbnail of #{project}/#{image}"
        tmp_image = generate_thumbnail(image)

        # Add image to sitemap
        Middleman::Sitemap::Resource.new(app.sitemap, project_thumbnail_resource_path(project, File.basename(tmp_image)), tmp_image).tap do |resource|
          resources << resource
        end
      end 
    end
    
    return resources
  end

  def register_extension_templates
    # We call reload_path to register the templates directory with Middleman.
    # The path given to app.files must be relative to the Middleman site's root.
    templates_dir_relative_from_root = Pathname(TEMPLATES_DIR).relative_path_from(Pathname(app.root))
    app.files.reload_path(templates_dir_relative_from_root)
  end

  def template(path)
    full_path = File.join(TEMPLATES_DIR, path)
    raise "Template #{full_path} not found" if !File.exist?(full_path)
    full_path
  end

  def manipulate_resource_list(resources)
    resources << portfolio_index_resource
    resources += project_resources
    resources += project_thumbnail_resources
    return resources
  end

  # get abs path to portfolio dir
  def portfolio_path
    File.join(app.source_dir, options.portfolio_dir) 
  end

  def portfolio_index_path
    "#{options.portfolio_dir}.html"
  end 

  def portfolio_index_resource
    source_file = template('index.html.erb')
    Middleman::Sitemap::Resource.new(app.sitemap, portfolio_index_path, source_file).tap do |resource|
      resource.add_metadata(options: { layout: false }, locals: {projects: projects})
    end
  end

  # get absolute path to project directory, eg: /path/to/site/portfolio/example-project/
  def project_dir(project)
    File.join(portfolio_path, project)
  end 

  # array of images for a project
  def project_images(project)
    Dir.glob(File.join(project_dir(project), '*'))
  end

  # Get all projects located in options.portfolio_dir
  def project_dirs
    #debug "Looking in #{options.portfolio_dir} for project subdirectories"
    Dir.glob(File.join(portfolio_path, '*')).select {|f| File.directory? f}
  end 

  def projects
    # Look for project directories
    projects = project_dirs.collect {|d| File.basename(d) }    
  end 

  # portfolio/example-project.html
  def project_resource_path(project)
    File.join(options.portfolio_dir, "#{project}.html")
  end

  # Generate resource path to project thumbnail, eg: "portfolio/example-project/1-thumbnail.jpg"
  def project_thumbnail_resource_path(project, thumbnail)
    File.join(options.portfolio_dir, project, thumbnail)
  end

  # thumbnail_name("1.jpg") => "1-200x150.jpg"
  def thumbnail_name(image)
    "#{File.basename(image, '.*')}-#{options.thumbnail_width}x#{options.thumbnail_height}#{File.extname(image)}"
  end

  def debug(str)
    puts str
  end

  helpers do
    def project_dir(project)

    end
  end
end

::Middleman::Extensions.register(:portfolio, Portfolio)
