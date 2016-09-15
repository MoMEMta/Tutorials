-- Load the library containing the matrix element
load_modules('../WW_FullyLeptonic/MatrixElement/build/libme_WW_emu.so')

-- Global parameters used by several modules
-- Changing these has NO impact on the value of the parameters used by the matrix element!
parameters = {
    energy = 13000.,
    W_mass = 80.419002,
    W_width = 2.047600,
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
    reco_particle = 'input::particles/1',
    sigma = 0.05,
}

GaussianTransferFunctionOnEnergy.tf_p2 = {
    ps_point = add_dimension(),
    reco_particle = 'input::particles/2',
    sigma = 0.05,
}

inputs = {
    'tf_p1::output',
    'tf_p2::output',
}


-- Use the BreitWignerGenerators to generate values distributed as the corresponding peaks,
-- for each propagator in the topology
BreitWignerGenerator.flatter_s13 = {
    ps_point = add_dimension(),
    mass = parameter('W_mass'),
    width = parameter('W_width')
}

BreitWignerGenerator.flatter_s24 = {
    ps_point = add_dimension(),
    mass = parameter('W_mass'),
    width = parameter('W_width')
}

-- The main block defines the phase-space parametrisation,
-- converts our particles given by the transfer functions, and our propagator masses
-- into solutions for the missing particles in the event
BlockF.blockf = {
    inputs = inputs,

    s13 = 'flatter_s13::s',
    s24 = 'flatter_s24::s',
    q1 = add_dimension(),
    q2 = add_dimension()
}

-- The Block generates a collection of "solutions", each containing reconstructed invisible particles (neutrinos)
-- and a corresponding Jacobian.
-- We now have to loop over this collection, and on each of these solutions:
--   - reconstruct the initial state
--   - evaluate the matrix element & PDFs
--   - multiply all the Jacobians with the matrix element and PDF values
-- The loop is taken care of using a Looper module, which takes as input the collection of solutions 
-- coming out of the Block, and a "Path" object defining the modules to be run in the loop: 
-- each of these modules has access to a single solution (accessed through the 'looper::solution' input tag).
Looper.looper = {
    solutions = 'blockf::solutions',
    path = Path('initial_state', 'WW', 'integrand')
}

--
-- Start of loop over solutions
--

    -- Using the fully reconstructed event (invisibles and visibles), build the initial state
    BuildInitialState.initial_state = {
        particles = inputs,
        solution = 'looper::solution',
    }

    jacobians = {'flatter_s13::jacobian', 'flatter_s24::jacobian', 'tf_p1::TF_times_jacobian', 'tf_p2::TF_times_jacobian'}

    -- This modules evaluates the matrix element and PDFs on the fully reconstructed event, and multiplies those
    -- with all the Jacobians it is given.
    MatrixElement.WW = {
      pdf = 'CT10nlo',
      pdf_scale = parameter('W_mass'),

      -- Name of the matrix element, defined in the .cc file of the ME 
      matrix_element = 'pp_WW_fully_leptonic',
      matrix_element_parameters = {
          card = '../WW_FullyLeptonic/MatrixElement/Cards/param_card.dat'
      },

      initialState = 'initial_state::partons',

      -- Configure how the Block's reconstructed particles and the input particles are linked to the matrix element (order and PID of the leg)
      -- The maps have to match the `mapFinalStates` index in the matrix element .cc file
      invisibles = {
        input = 'looper::solution',
        ids = {
          {
            pdg_id = 12,
            me_index = 2,
          },

          {
            pdg_id = -14,
            me_index = 4,
          }
        }
      },

      particles = {
        inputs = inputs,
        ids = {
          {
            pdg_id = -11,
            me_index = 1,
          },

          {
            pdg_id = 13,
            me_index = 3,
          },
        }
      },

      -- Other jacobians: only one value each
      jacobians = jacobians
    }

    -- The last module in the loop is a "Summer": it sums the value defined as input when looping over the solutions
    -- This allows to define the actual integrand (which is the sum of the product ME*PDF*PDF*Jacobians evaluated on each solution)
    DoubleSummer.integrand = { input = 'WW::output' }

--
-- End of loop over solutions
--

-- Register with MoMEMta which output defines the integrand
integrand('integrand::sum')
