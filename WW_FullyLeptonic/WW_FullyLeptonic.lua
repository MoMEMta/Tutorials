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
GaussianTransferFunction.tf_p1 = {
    -- getpspoint() generates an input tag of type `cuba::ps_points/i`
    -- where `i` is automatically incremented each time the function is called.
    ps_point = getpspoint(),
    reco_particle = 'input::particles/1',
    sigma = 0.05,
}

GaussianTransferFunction.tf_p2 = {
    ps_point = getpspoint(),
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
    ps_point = getpspoint(),
    mass = parameter('W_mass'),
    width = parameter('W_width')
}

BreitWignerGenerator.flatter_s24 = {
    ps_point = getpspoint(),
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
    q1 = getpspoint(),
    q2 = getpspoint()
}

-- Using the fully reconstructed event (invisibles and visibles), build the initial state
BuildInitialState.initial_state = {
    particles = inputs,
    invisibles = {
        'blockf::invisibles',
    },
}

jacobians = {'flatter_s13::jacobian', 'flatter_s24::jacobian', 'tf_p1::TF_times_jacobian', 'tf_p2::TF_times_jacobian'}

-- This module defines the `integrands` output, which will be taken by MoMEMta as the value to integrate
MatrixElement.WW = {
  pdf = 'CT10nlo',
  pdf_scale = parameter('W_mass'),

  -- Name of the matrix element, defined in the .cc file of the ME 
  matrix_element = 'pp_WW_fully_leptonic',
  matrix_element_parameters = {
      card = '../WW_FullyLeptonic/MatrixElement/Cards/param_card.dat'
  },

  initialState = 'initial_state::output',

  invisibles = {
    input = 'blockf::invisibles',
    -- Jacobians of the block: one value per invisibles' solution
    jacobians = 'blockf::jacobians',
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

  -- Configure how the inputs are linked to the matrix element (order and PID of the leg)
  -- Together with the invisibles' ids, it has to match the `mapFinalStates` index in the matrix element .cc file
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
