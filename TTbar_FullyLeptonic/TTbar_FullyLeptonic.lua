-- Load the library containing the matrix element
load_modules('../TTbar_FullyLeptonic/MatrixElement/build/libme_TTbar_ee.so')

-- Declare inputs required by this configuration file. Since it's TTbar fully leptonic, we expect 4 inputs,
-- the two leptons and the two bjets
-- P4 for each particle are passed when calling the C++ `computeWeights` function
local lepton1 = declare_input("lepton1")
local lepton2 = declare_input("lepton2")
local bjet1 = declare_input("bjet1")
local bjet2 = declare_input("bjet2")

-- Global parameters used by several modules
-- Changing these has NO impact on the value of the parameters used by the matrix element!
parameters = {
    energy = 13000.,
    top_mass = 173.,
    top_width = 1.491500,
    W_mass = 80.419002,
    W_width = 2.047600,

    -- You can export a graphviz representation of the computation graph using the
    -- `export_graph_as` parameter
    -- Use the `dot` command to convert the graph into a PDF
    -- dot -Tpdf TTbar_fullyleptonic_computing_graph.dot -o TTbar_fullyleptonic_computing_graph.pdf
    export_graph_as = "TTbar_fullyleptonic_computing_graph.dot"
}

-- Configuration of Cuba
cuba = {
    relative_accuracy = 0.05,
    verbosity = 3
}

-- The transfer functions take as input the particles passed in the computeWeights() function,
-- and each add a dimension of integration
GaussianTransferFunctionOnEnergy.tf_p1 = {
    -- add_dimension() generates an input tag allowing the retrieve a new phase-space point component,
    -- and it notifies MoMEMta that a new integration dimension is requested
    ps_point = add_dimension(),
    -- We use the directly the inputs declared above. The `reco_p4` attribute returns the correct input tag
    reco_particle = lepton1.reco_p4,
    sigma = 0.05,
}

-- We can assign to each input a `gen` p4. By default, the gen p4 is the same as the reco one, which is useful when
-- no transfer function is applied. Here however, we applied a transfer function to the `lepton1` input, meaning that the
-- output of the `tf_p1` module correspond now to the `gen` p4 of `lepton1`. To reflect that, we explicitly set the gen p4 
-- to be the output of the `tf_p1` module
lepton1.set_gen_p4("tf_p1::output");

GaussianTransferFunctionOnEnergy.tf_p2 = {
    ps_point = add_dimension(),
    reco_particle = lepton2.reco_p4,
    sigma = 0.10,
}

lepton2.set_gen_p4("tf_p2::output")

GaussianTransferFunctionOnEnergy.tf_p3 = {
    ps_point = add_dimension(),
    reco_particle = bjet1.reco_p4,
    sigma = 0.05,
}

bjet1.set_gen_p4("tf_p3::output");

GaussianTransferFunctionOnEnergy.tf_p4 = {
    ps_point = add_dimension(),
    reco_particle = bjet2.reco_p4,
    sigma = 0.10,
}

bjet2.set_gen_p4("tf_p4::output");

inputs_before_perm = {
    'tf_p1::output',
    'tf_p2::output',
    'tf_p3::output',
    'tf_p4::output',
}

-- We want to automatically generate permutation between the two bjet using the MC
-- This function inserts a Permutator module and swap the `gen` p4 of each inputs to
-- points to the output of this module
-- Note that we can also choose to do the permutation **before** the transfer function
-- In this case, the function to use is `add_reco_permutations` and must be called before
-- defining transfer functions
add_gen_permutations(bjet1, bjet2)

inputs = {
  lepton1.gen_p4,
  bjet1.gen_p4,
  lepton2.gen_p4,
  bjet2.gen_p4
}

-- Use the BreitWignerGenerators to generate values distributed as the corresponding peaks,
-- for each propagator in the topology
BreitWignerGenerator.flatter_s13 = {
    ps_point = add_dimension(),
    mass = parameter('W_mass'),
    width = parameter('W_width')
}

BreitWignerGenerator.flatter_s134 = {
    ps_point = add_dimension(),
    mass = parameter('top_mass'),
    width = parameter('top_width')
}

BreitWignerGenerator.flatter_s25 = {
    ps_point = add_dimension(),
    mass = parameter('W_mass'),
    width = parameter('W_width')
}

BreitWignerGenerator.flatter_s256 = {
    ps_point = add_dimension(),
    mass = parameter('top_mass'),
    width = parameter('top_width')
}

-- The main block defines the phase-space parametrisation,
-- converts our particles given by the transfer functions, and our propagator masses
-- into solutions for the missing particles in the event
BlockD.blockd = {
    p3 = inputs[1],
    p4 = inputs[2],
    p5 = inputs[3],
    p6 = inputs[4],

    -- Fix the neutrino transverse momentum to the experimental MET passed to MoMEMta
    pT_is_met = true,

    s13 = 'flatter_s13::s',
    s134 = 'flatter_s134::s',
    s25 = 'flatter_s25::s',
    s256 = 'flatter_s256::s',
}

-- The Block generates a collection of "solutions", each containing reconstructed invisible particles (neutrinos)
-- and a corresponding Jacobian.
-- We now have to loop over this collection, and on each of these solutions:
--   - reconstruct the initial state
--   - evaluate the matrix element & PDFs
--   - multiply all the Jacobians with the matrix element and PDF values
-- The loop is taken care of using a Looper module, which takes as input the collection of solutions 
-- coming out of the Block, and a "Path" object defining the modules to be run in the loop: 
-- each of these modules has access to a single solution (accessed through the 'looper::particles/i' and 'looper::jacobian' input tags).
Looper.looper = {
    solutions = 'blockd::solutions',
    path = Path('boost', 'ttbar', 'integrand')
}

--
-- Start of loop over solutions
--

    -- We now have reconstructed all particles, so we define a new set of inputs to be used inside the loop:
    full_inputs = { 'looper::particles/1', 'looper::particles/2', inputs[1], inputs[2], inputs[3], inputs[4] }
    
    -- Using the fully reconstructed event, build the initial state
    BuildInitialState.boost = {
        particles = full_inputs,

        -- Since the neutrinos were reconstructed using the experimental MET,
        -- the event has non-zero total transverse momentum,
        -- so we have to do the boost to define an initial state satisfying conservation
        -- of momentum.
        do_transverse_boost = true
    }

    jacobians = { 'flatter_s13::jacobian', 'flatter_s134::jacobian', 'flatter_s25::jacobian', 'flatter_s256::jacobian', 'tf_p1::TF_times_jacobian', 'tf_p2::TF_times_jacobian', 'tf_p3::TF_times_jacobian', 'tf_p4::TF_times_jacobian', 'looper::jacobian' }

    -- This modules evaluates the matrix element and PDFs on the fully reconstructed event, and multiplies those
    -- with all the Jacobians it is given.
    MatrixElement.ttbar = {
      pdf = 'CT10nlo',
      pdf_scale = parameter('top_mass'),

      -- Name of the matrix element, defined in the .cc file of the ME 
      matrix_element = 'TTbar_ee_sm_P1_Sigma_sm_gg_epvebemvexbx',
      matrix_element_parameters = {
          card = '../TTbar_FullyLeptonic/MatrixElement/Cards/param_card.dat'
      },

      initialState = 'boost::partons',

      -- Configure how particles are linked to the matrix element (order and PID of the leg)
      -- The maps have to match the `mapFinalStates` index in the matrix element .cc file
      -- The order of the entries in the 'ids' parameter corresponds to the order of the particles as given
      -- in the 'input'.
      particles = {
        inputs = full_inputs,
        ids = {
          {
            pdg_id = 12,
            me_index = 2,
          },
          {
            pdg_id = -12,
            me_index = 5,
          },
          {
            pdg_id = -11,
            me_index = 1,
          },
          {
            pdg_id = 5,
            me_index = 3,
          },
          {
            pdg_id = 11,
            me_index = 4,
          },
          {
            pdg_id = -5,
            me_index = 6,
          },
        }
      },

      -- Other jacobians
      jacobians = jacobians
    }

    -- The last module in the loop is a "Summer": it sums the value defined as input when looping over the solutions
    -- This allows to define the actual integrand (which is the sum of the product ME*PDF*PDF*Jacobians evaluated on each solution)
    DoubleLooperSummer.integrand = { input = 'ttbar::output' }

--
-- End of loop over solutions
--

-- Register with MoMEMta which output defines the integrand
integrand('integrand::sum')
